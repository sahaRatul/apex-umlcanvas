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
}