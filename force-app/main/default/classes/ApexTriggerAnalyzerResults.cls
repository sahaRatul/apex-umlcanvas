public with sharing class ApexTriggerAnalyzerResults {
    public ApexTriggerAnalyzerResults() {
        this.activeTriggers = new List<String>();
        this.inactiveTriggers = new List<String>();
        this.deletedTriggers = new List<String>();
        this.managedTriggers = new List<String>();
        this.invalidTriggers = new List<String>();
        this.eventDuplicates = new List<EventDuplicate>();
        this.loopDmls = new List<LoopDML>();
    }
    @AuraEnabled
    public String objectName{get;set;}
    @AuraEnabled
    public List<String> activeTriggers{get;set;}
    @AuraEnabled
    public List<String> inactiveTriggers{get;set;}
    @AuraEnabled
    public List<String> deletedTriggers{get;set;}
    @AuraEnabled
    public List<String> managedTriggers{get;set;}
    @AuraEnabled
    public List<String> invalidTriggers{get;set;}
    @AuraEnabled
    public Map<String, List<String>> hardCodedIdObjects {get;set;}
    @AuraEnabled
    public Map<String, Integer> SOQLQueries {get;set;}
    @AuraEnabled
    public Map<String,Integer> SOQLQuerieswithwhereclause {get;set;}
    @AuraEnabled
    public Map<String,Integer> SOQLQuerieswithoutwhereclause {get;set;}
    @AuraEnabled
    public List<EventDuplicate> eventDuplicates {get;set;}
    @AuraEnabled
    public List<LoopDML> loopDmls {get;set;}
 
    public class EventDuplicate {
        public EventDuplicate() {
            this.presentInTriggers = new List<String>();
        }
        @AuraEnabled
        public String eventName{get;set;}
        @AuraEnabled
        public List<String> presentInTriggers{get;set;}
         @AuraEnabled
        public String objectName {get;set;}
    }

    public class LoopDML {
        public LoopDML() {
            this.dmlStatements = new Map<Integer, String>();
        }

        public LoopDML(String triggerName, Map<Integer, String> dmlStatements) {
            this.triggerName = triggerName;
            this.dmlStatements = dmlStatements;
        }
        @AuraEnabled
        public String triggerName {get;set;}
        @AuraEnabled
        public Map<Integer, String> dmlStatements{get;set;}
    }

    public class PDFWrapper {
        @AuraEnabled
        public String eventName{get;set;}
        @AuraEnabled
        public List<String> presentInTriggers{get;set;}
        @AuraEnabled
        public String objName{get;set;}
        @AuraEnabled
        public String loopType {get;set;}
        @AuraEnabled
        public Map<Integer, String> dmlStatements{get;set;}
    }
    
    @AuraEnabled
    public static PDFWrapper GetPDFData(){
        PDFWrapper pwrapper =  new PDFWrapper();
        EventDuplicate ED = new EventDuplicate();
        pwrapper.objName = ED.objectName;
        pwrapper.eventName= ED.eventName;
        pwrapper.presentInTriggers=ED.presentInTriggers;
        return pwrapper;
    }
}