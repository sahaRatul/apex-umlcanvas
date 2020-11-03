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
    }

    public class LoopDML {
        public LoopDML() {
            this.dmlStatements = new Map<Integer, String>();
        }
        @AuraEnabled
        public String loopType {get;set;}
        @AuraEnabled
        public Map<Integer, String> dmlStatements{get;set;}
    }
}
