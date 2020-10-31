public with sharing class ApexTriggerAnalyzerResults {
    public ApexTriggerAnalyzerResults() {
        this.activeTriggers = new List<String>();
        this.inactiveTriggers = new List<String>();
        this.deletedTriggers = new List<String>();
        this.managedTriggers = new List<String>();
        this.invalidTriggers = new List<String>();
        this.eventDuplicates = new List<EventDuplicates>();
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
    public List<EventDuplicates> eventDuplicates {get;set;}

    public class EventDuplicates {
        public EventDuplicates() {
            this.presentInTriggers = new List<String>();
        }
        @AuraEnabled
        public String eventName{get;set;}
        @AuraEnabled
        public List<String> presentInTriggers{get;set;}
    }
}
