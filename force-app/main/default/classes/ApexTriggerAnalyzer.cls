public with sharing class ApexTriggerAnalyzer {
    public ApexTriggerAnalyzer() {
        
    }
    
    @AuraEnabled
    public static ApexTriggerAnalyzerResults analyzeObjectTriggers(String objectName) {
        ApexTriggerAnalyzerResults results = new ApexTriggerAnalyzerResults();
        
        //Get ApexTriggers for an object
        List<ApexTrigger> apexTriggers = ApexTriggerAnalyzer.getApexTriggerData(objectName);
        
        //Check Triggers for duplicated events
        ApexTriggerAnalyzerResults result = ApexTriggerAnalyzer.checkTriggersForDuplicateEvents(objectName, apexTriggers, results);
        
        //Separate Active, Inactive, Deleted, Managed and Invalid triggers
        result = ApexTriggerAnalyzer.classifyTriggers(apexTriggers, result);
        
        //Check for Loops
        result = ApexTriggerAnalyzer.findDmlInsideLoops(apexTriggers, result);
        
        //check hardcoded ids in a trigger
        result = checkTriggersForHardCodedIDs(apexTriggers, result);
        
        //Check for Queries without where clause
        
        result = ApexTriggerAnalyzer.Querieswithoutwhereclause(apexTriggers, result);
        
        return result;
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
        for(ApexTrigger apexTrigger : apexTriggers) {
            //Remove comments from body
            String cleanedupBody = ApexTriggerAnalyzerUtils.removeCommentsFromCode(apexTrigger.body);

            //Get list of loops and their position in source code
            Map<Integer,String> loopPositionMap = ApexTriggerAnalyzerUtils.detectLoopsFromCode(cleanedupBody);

            //Get the code block inside loop now
            List<String> loopBodies = ApexTriggerAnalyzerUtils.getLoopBodies(loopPositionMap, cleanedupBody);
            System.debug(loopBodies);
        }
        return result;
    }
    
    private static ApexTriggerAnalyzerResults checkTriggersForHardCodedIDs(List<ApexTrigger> apexTriggers, ApexTriggerAnalyzerResults result){
        
        Map<String, String> triggerNamesWithBodyWithoutComments = new Map<String, String>();
        Map<String, String> mapOfObjNameAndPrefix = new Map<String,String>();
        List<String> idsPerTrigger = new List<String>();
        Map<String, List<Integer>> idsPerTriggerWithLineNumbers = new Map<String, List<Integer>>();
        Map<String, List<String>> hardCodedIdsresult = new Map<String, List<String>>();
        Map<String, List<String>> hardCodedIdsresultWithBodyMap = new Map<String, List<String>>();
        triggerNamesWithBodyWithoutComments = ApexTriggerAnalyzerUtils.removeCommentedCodeFromTrigger(apexTriggers);
        
         for ( Schema.SObjectType obj : Schema.getGlobalDescribe().values() )
        {
            Schema.DescribeSObjectResult objResult = obj.getDescribe();
            String objName = objResult.getName();
            String objPrefix = objResult.getKeyPrefix();
            if(objPrefix != null){
            mapOfObjNameAndPrefix.put(objPrefix, objName);
            }
        }
        
        
      //removing hardcoded ids logic
        for(String trigName : triggerNamesWithBodyWithoutComments.keySet()){
            String triggerBody = triggerNamesWithBodyWithoutComments.get(trigName);
            
            for(String prefix : mapOfObjNameAndPrefix.keySet()){
                
                if(triggerBody.contains(prefix)){
                    system.debug('CountMatches'+prefix+triggerBody.countMatches(prefix));
                    Integer countOfIds = triggerBody.countMatches(prefix);
                    for(Integer i = 0; i< countOfIds; i++){
                        String finalId = prefix+triggerBody.substringBetween(prefix,'\'');
                        system.debug('Final Ids===>' +finalId);
                        if(finalId.length() == 15 || finalId.length() == 18){
                            Type typ = Type.forName(mapOfObjNameAndPrefix.get(prefix));
                            if(CheckValidSalesforceIDUtility.isValidSalesforceId(finalId, typ)){
                                triggerBody = triggerBody.remove(finalId);
                                idsPerTrigger.add(finalId);
                                
                            }
                        }
                    }
                    if(idsPerTrigger.size() !=0){
                        
                        hardCodedIdsresultWithBodyMap.put(triggerBody , idsPerTrigger);
                        //To get line numbers of IDs
                       //idsPerTriggerWithLineNumbers =  ApexTriggerAnalyzerUtils.getLineNumberOfTrigger(hardCodedIdsresultWithBodyMap);
                       
                        
                        hardCodedIdsresult.put(trigName , idsPerTrigger);
                        result.hardCodedIdObjects = hardCodedIdsresult;
                    }else{
                        //set a flag 
                    }
                }
            }
        }
        
        system.debug('final hardcoded Ids in a trigger==> '+result.hardCodedIdObjects);
        system.debug('final hardcoded Ids in a trigger==> '+idsPerTriggerWithLineNumbers);
        return result;
    }
    
     private static ApexTriggerAnalyzerResults Querieswithoutwhereclause(List<ApexTrigger> apexTriggers, ApexTriggerAnalyzerResults result) {
        Integer countOfQueries=0;
        Map<String, String> triggerNamesWithBodyWithoutComments = new Map<String, String>();
        Map<String, String> mapOfObjName = new Map<String,String>();
        Map<String, Integer> ObjnameewithSOQL = new Map<String, Integer>();
        Map<String, Integer>SOQLwithwhereclause = new Map<String, Integer>();
        Map<String, Integer>SOQLwithoutwhereclause = new Map<String, Integer>();
        triggerNamesWithBodyWithoutComments = ApexTriggerAnalyzerUtils.removeCommentedCodeFromTrigger(apexTriggers);
        for ( Schema.SObjectType obj : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult objResult = obj.getDescribe();
            String objName = objResult.getName();
            String SelectString ='select';
            mapOfObjName.put(SelectString, objName);
        }
        for(String trigName : triggerNamesWithBodyWithoutComments.keySet()){
            Integer d =0;
            String triggerBody = triggerNamesWithBodyWithoutComments.get(trigName).toLowerCase();
            
            for(String prefix : mapOfObjName.keySet()) {
                countOfQueries = triggerBody.countMatches('select');
                system.debug('countOfQueries'+countOfQueries);
                ObjnameewithSOQL.put(trigName, countOfQueries);   
                System.debug('ObjnameewithSOQL'+ObjnameewithSOQL);
                result.SOQLQueries = ObjnameewithSOQL;
                Integer Querieswithwhereclause = triggerBody.countMatches('where');
                system.debug('Querieswithwhereclause'+Querieswithwhereclause);
                SOQLwithwhereclause.put(trigName, Querieswithwhereclause);
                result.SOQLQuerieswithoutwhereclause=SOQLwithwhereclause;
                system.debug('SOQLwithwhereclause'+SOQLwithwhereclause);
                Integer Querieswithoutwhereclause = countOfQueries-Querieswithwhereclause;
                system.debug('Withoutwhereclause'+Querieswithoutwhereclause);
                SOQLwithoutwhereclause.put(trigName, Querieswithoutwhereclause);
                system.debug('SOQLwithoutwhereclause'+SOQLwithoutwhereclause);
                result.SOQLQuerieswithoutwhereclause = SOQLwithoutwhereclause;
            }
        }
        return result;
    }
}