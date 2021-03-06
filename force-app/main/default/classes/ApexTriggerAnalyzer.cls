public with sharing class ApexTriggerAnalyzer {
    public string recordId {get;set;}

    public ApexTriggerAnalyzer(ApexPages.StandardController controller) {
        recordID = ApexPages.CurrentPage().getparameters().get('id'); 
    }

    @AuraEnabled
    public static List<ApexTrigger> getApexTriggerListWithIds(List<String> objectNames){
        return [SELECT Id, Name from ApexTrigger WHERE TableEnumOrId =: ObjectNames];
    }

    @AuraEnabled
    public static string getStoredReport(String reportId){
        try {
            List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink where LinkedEntityId =: Id.valueOf(reportId)];
            Set<Id> documentIds = new Set<Id>();
            for(ContentDocumentLink documentLink: contentDocumentLinks) {
                documentIds.add(documentLink.ContentDocumentId);
            }
            List<ContentVersion> contentVersions = [SELECT VersionData, Title FROM ContentVersion WHERE ContentDocumentId in :documentIds AND IsLatest = true];
            if(contentVersions.size() > 0) {
                return contentVersions[0].VersionData.toString();
            }
            else {
                return '[]';
            }
        } catch (Exception e) {
            return '[]';
        }
    }
    
    @AuraEnabled
    public static Id analyzeObjectTriggers(List<String> objectNames , String trigerReportName) {
        List<ApexTriggerAnalyzerResults> resultList = new List<ApexTriggerAnalyzerResults>();

        for(String objectName : objectNames) {
            ApexTriggerAnalyzerResults results = new ApexTriggerAnalyzerResults();
        
            //Get ApexTriggers for an object
            List<ApexTrigger> apexTriggers = ApexTriggerAnalyzer.getApexTriggerData(objectName);
    
            //Separate Active, Inactive, Deleted, Managed and Invalid triggers
            results = ApexTriggerAnalyzer.classifyTriggers(apexTriggers, results);
            
            //Check Triggers for duplicated events
            results = ApexTriggerAnalyzer.checkTriggersForDuplicateEvents(objectName, apexTriggers, results);
            
            //Check for Loops
            results = ApexTriggerAnalyzer.findDmlInsideLoops(apexTriggers, results);
            
            //check hardcoded ids in a trigger
            results = ApexTriggerAnalyzer.checkTriggersForHardCodedIDs(apexTriggers, results);
            
            //Check for Queries without where clause
            results = ApexTriggerAnalyzer.getQueriesWithoutWhereClause(apexTriggers, results);

            resultList.add(results);
        }
        return ApexTriggerAnalyzer.generateReportRecord(resultList , trigerReportName);
    }
    
    private static List<ApexTrigger> getApexTriggerData(String ObjectName) {
        //Query ApexTrigger
        return [
            SELECT Name, Body, TableEnumOrId, NamespacePrefix, ApiVersion, Status, 
            IsValid,UsageAfterDelete,UsageAfterInsert,UsageAfterUndelete,
            UsageAfterUpdate,UsageBeforeDelete,UsageBeforeInsert,UsageBeforeUpdate, 
            UsageIsBulk FROM ApexTrigger WHERE TableEnumOrId =: ObjectName
        ];
    }

    private static Id generateReportRecord(List<ApexTriggerAnalyzerResults> results , String triggerReportName) {
        Trigger_Analyzer_Report__c report = new Trigger_Analyzer_Report__c();
        report.TrigerAnalyser_Report_Name__c = triggerReportName;
        insert report;

        String jsonReport = ApexTriggerAnalyzerUtils.getJsonReport(results);
        ApexFileUpload.uploadFile(jsonReport, 'report.json', report.id);

        System.debug('report Id ===> ' + report.id);

        return report.id;
    }
    
    private static ApexTriggerAnalyzerResults checkTriggersForDuplicateEvents(String objectName, List<ApexTrigger> apexTriggers, ApexTriggerAnalyzerResults result) {
        List<String> eventNames = new List<String>{'UsageBeforeInsert','UsageBeforeUpdate','UsageBeforeDelete','UsageAfterInsert','UsageAfterUpdate','UsageAfterUndelete','UsageAfterDelete','UsageIsBulk'};
            
            //Add objectName to AnalyzerResult
            result.objectName = objectName;
        
        for(String eventName: eventNames) {
            ApexTriggerAnalyzerResults.EventDuplicate duplicates = new ApexTriggerAnalyzerResults.EventDuplicate();
            //Check for duplicates
            for(ApexTrigger apexTrigger: apexTriggers) {
                duplicates.eventName = eventName.remove('Usage');
                if((Boolean)apexTrigger.get(eventName)) {
                    duplicates.presentInTriggers.add(apexTrigger.Name);
                }
            }
            if(duplicates.presentInTriggers.size() > 1) {
                result.eventDuplicates.add(duplicates);
            }
        }
        
        return result;
    }
    
    private static ApexTriggerAnalyzerResults classifyTriggers(List<ApexTrigger> apexTriggers, ApexTriggerAnalyzerResults result) {
        for(ApexTrigger apexTrigger : apexTriggers) {
            switch on apexTrigger.Status {
                when 'Active' {
                    result.activeTriggers.add(apexTrigger.Name);
                }
                when 'Inactive' {
                    result.inactiveTriggers.add(apexTrigger.Name);
                }
                when else {
                    result.deletedTriggers.add(apexTrigger.Name);
                }
            }
            
            if(apexTrigger.Body == '(hidden)') {
                result.managedTriggers.add(apexTrigger.Name);
            }
            
            if(!apexTrigger.IsValid) {
                result.invalidTriggers.add(apexTrigger.Name);
            }
        }
        return result;
    }
    
    private static ApexTriggerAnalyzerResults findDmlInsideLoops(List<ApexTrigger> apexTriggers, ApexTriggerAnalyzerResults result) {
        Map<String, String> cleanedUpTriggers = ApexTriggerAnalyzerUtils.removeCommentedCodeFromTrigger(apexTriggers, true);

        for(String trig: cleanedUpTriggers.keySet()) {
            //Remove single and multiline comments from code
            String cleanedupBody = cleanedUpTriggers.get(trig);

            //Get list of loops and their position in source code
            Map<Integer,String> loopPositionMap = ApexTriggerAnalyzerUtils.detectLoopsFromCode(cleanedupBody);

            //Get the code block inside loop now
            List<String> loopBodies = ApexTriggerAnalyzerUtils.getLoopBodies(loopPositionMap, cleanedupBody);
            
            Map<Integer, String> statements = ApexTriggerAnalyzerUtils.getQueryStatementsFromCode(loopBodies, cleanedupBody);
            
            result.loopDmls.add(new ApexTriggerAnalyzerResults.LoopDML(trig, statements));
        }

        return result;
    }
    
     private static ApexTriggerAnalyzerResults checkTriggersForHardCodedIDs(List<ApexTrigger> apexTriggers, ApexTriggerAnalyzerResults result){
        Map<String, String> triggerNamesWithBodyWithoutComments = new Map<String, String>();
        Map<String, String> mapOfObjNameAndPrefix = new Map<String,String>();
        List<Integer> idsPerTriggerWithLineNumbers = new List<Integer>();
        triggerNamesWithBodyWithoutComments = ApexTriggerAnalyzerUtils.removeCommentedCodeFromTrigger(apexTriggers, true);

        for (Schema.SObjectType obj : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult objResult = obj.getDescribe();
            String objName = objResult.getName();
            String objPrefix = objResult.getKeyPrefix();
            if(objPrefix != null) {
                mapOfObjNameAndPrefix.put(objPrefix, objName);
            }
        }
        
        //removing hardcoded ids logic
        for(String trigName : triggerNamesWithBodyWithoutComments.keySet()){
            String triggerBody = triggerNamesWithBodyWithoutComments.get(trigName);
            for(String prefix : mapOfObjNameAndPrefix.keySet()){
                if(triggerBody.contains(prefix)){
                    Integer countOfIds = triggerBody.countMatches(prefix);
                    Map<Integer, String> lineNumberIdMap = new Map<Integer, String>();

                    for(Integer i = 0; i < countOfIds; i++) {
                        String finalId = prefix + triggerBody.substringBetween(prefix,'\'');
                        if(finalId.length() == 15 || finalId.length() == 18){
                            Type typ = Type.forName(mapOfObjNameAndPrefix.get(prefix));
                            if(CheckValidSalesforceIDUtility.isValidSalesforceId(finalId, typ)){
                                idsPerTriggerWithLineNumbers = ApexTriggerAnalyzerUtils.getLineNumberOfTrigger(triggerBody , finalId);
                                for(Integer lineNumber: idsPerTriggerWithLineNumbers) {
                                    if(!lineNumberIdMap.containsKey(lineNumber))
                                        lineNumberIdMap.put(lineNumber, finalId);
                                }
                            }
                        }
                    }
                    if(!lineNumberIdMap.isEmpty()) {
                        ApexTriggerAnalyzerResults.HardCodedId harcodedId = new ApexTriggerAnalyzerResults.HardCodedId(trigName, lineNumberIdMap);
                        result.hardCodedIds.add(harcodedId);
                    }
                }
            }
        }
        return result;
    }
    
    private static ApexTriggerAnalyzerResults getQueriesWithoutWhereClause(List<ApexTrigger> apexTriggers, ApexTriggerAnalyzerResults result) {
        Integer countOfQueries=0;
        Map<String, String> triggerNamesWithBodyWithoutComments = new Map<String, String>();
        Map<String, String> mapOfObjName = new Map<String,String>();
        Map<String, Integer> objNameWithSoql = new Map<String, Integer>();
        Map<String, Integer> soqlWithWhereClause = new Map<String, Integer>();
        Map<String, Integer> soqlWithoutWhereClause = new Map<String, Integer>();
        triggerNamesWithBodyWithoutComments = ApexTriggerAnalyzerUtils.removeCommentedCodeFromTrigger(apexTriggers, false);
        
        for (Schema.SObjectType obj : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult objResult = obj.getDescribe();
            String objName = objResult.getName();
            String SelectString ='select';
            mapOfObjName.put(SelectString, objName);
        }
        
        for(String trigName : triggerNamesWithBodyWithoutComments.keySet()){
            Integer d = 0;
            String triggerBody = triggerNamesWithBodyWithoutComments.get(trigName).toLowerCase();
            Integer queriesWithWhereClause = 0;
            Integer queriesWithoutWhereClause = 0;

            for(String prefix : mapOfObjName.keySet()) {
                countOfQueries = triggerBody.countMatches('select');
                objNameWithSoql.put(trigName, countOfQueries);   
                queriesWithWhereClause = triggerBody.countMatches('where');
                soqlWithWhereClause.put(trigName, queriesWithWhereClause);
                queriesWithoutWhereClause = countOfQueries - queriesWithWhereClause;
                soqlWithoutWhereClause.put(trigName, queriesWithoutWhereClause);
            }
            result.soqlStatistics.add(new ApexTriggerAnalyzerResults.SoqlStatistics(trigName, countOfQueries, queriesWithWhereClause, queriesWithoutWhereClause));
        }
        return result;
    }
    
    /***********************************************************************************************************************
     * Method invoked from Objects_Selection_dropdown_Comp that displays SObjects.     
     * *********************************************************************************************************************/
    @AuraEnabled
    public static objectsAndErrorMessageWrapper fetchSObjectList(){
        Set<String> objectswithTrigger = new Set<String>();
        List<String> objectswithTriggerList = new List<String>();
        List<ApexTrigger> activeTriggers = new List<ApexTrigger>();
        objectsAndErrorMessageWrapper objectWrapper = new objectsAndErrorMessageWrapper();
        try {
            activeTriggers = getActiveTriggers();
        } catch(Exception e) {
            System.debug('Error Message is=> '+ e.getMessage());
            System.debug('Error Line is=> '+ e.getLineNumber());
            objectWrapper.errorMessage = 'EXCEPTION';
        }
        if(!activeTriggers.isEmpty()){
            for(ApexTrigger rec :  activeTriggers){
                if(rec.Body == '(hidden)') {
                    String objectName = rec.TableEnumOrId +'  [⇩]';
                    objectsWithTrigger.add(objectName);
                } else {
                    objectsWithTrigger.add(rec.TableEnumOrId);
                }
            }
            objectWrapper.errorMessage = 'SUCCESS';  
        }
        system.debug(objectswithTrigger);
        objectswithTriggerList.addAll(objectswithTrigger);
        objectswithTriggerList.sort();
        objectWrapper.sObjectNames = objectswithTriggerList;
        return objectWrapper;
    }
    
    //Get the list of active trigers to display on the drop down
    private static List<ApexTrigger> getActiveTriggers(){
        return [Select name,TableEnumOrId,body,Status from ApexTrigger where Status = 'Active'];
    }
    
    //Wrapper Class for storing List of objects and error message
    public class objectsAndErrorMessageWrapper {
        @AuraEnabled
        public List<String> sObjectNames{set;get;}
        @AuraEnabled
        public String errorMessage{set;get;}
    }
}