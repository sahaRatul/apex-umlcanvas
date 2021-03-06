public with sharing class ApexTriggerAnalyzerResults {
    public ApexTriggerAnalyzerResults() {
        this.activeTriggers = new List<String>();
        this.inactiveTriggers = new List<String>();
        this.deletedTriggers = new List<String>();
        this.managedTriggers = new List<String>();
        this.invalidTriggers = new List<String>();
        this.eventDuplicates = new List<EventDuplicate>();
        this.loopDmls = new List<LoopDML>();
        this.hardCodedIds = new List<HardCodedId>();
        this.soqlStatistics = new List<SoqlStatistics>();
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
    @AuraEnabled
    public List<HardCodedId> hardCodedIds {get;set;}
    @AuraEnabled
    public List<SoqlStatistics> soqlStatistics{get; set;}
 
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

    public class HardCodedId {
        public HardCodedId() {
            this.hardCodedIds = new Map<Integer, String>();
        }

        public HardCodedId(String triggerName, Map<Integer, String> hardCodedIds) {
            this.triggerName = triggerName;
            this.hardCodedIds = hardCodedIds;
        }

        @AuraEnabled
        public String triggerName {get;set;}
        @AuraEnabled
        public Map<Integer, String> hardCodedIds{get;set;}
    }

    public class SoqlStatistics {
        public SoqlStatistics(String triggerName, Integer soqlQueryCount, Integer soqlQueriesWithWhereClauseCount, Integer soqlQueriesWithoutWhereClauseCount) {
            this.triggerName = triggerName;
            this.soqlQueryCount = soqlQueryCount;
            this.soqlQueriesWithWhereClauseCount = soqlQueriesWithWhereClauseCount;
            this.soqlQueriesWithoutWhereClauseCount = soqlQueriesWithoutWhereClauseCount;
        }

        @AuraEnabled
        public String triggerName {get;set;}
        @AuraEnabled
        public Integer soqlQueryCount {get;set;}
        @AuraEnabled
        public Integer soqlQueriesWithWhereClauseCount {get;set;}
        @AuraEnabled
        public Integer soqlQueriesWithoutWhereClauseCount {get;set;}
    }

    public void generateJSON(ApexTriggerAnalyzerResults result, JSONGenerator gen) {
        gen.writeStartObject();

        gen.writeStringField('objectName', result.objectName);
        gen.writeStringField('objectApiName', result.objectName);

        //Basic trigger information tab data starts here
        gen.writeFieldName('triggerDetails');
        gen.writeStartObject();
        gen.writeFieldName('activeTriggers');
        gen.writeStartArray();
        for(String trg: result.activeTriggers) {
            gen.writeString(trg);
        }
        gen.writeEndArray();
        gen.writeFieldName('inactiveTriggers');
        gen.writeStartArray();
        for(String trg: result.inactiveTriggers) {
            gen.writeString(trg);
        }
        gen.writeEndArray();
        gen.writeFieldName('invalidTriggers');
        gen.writeStartArray();
        for(String trg: result.invalidTriggers) {
            gen.writeString(trg);
        }
        gen.writeEndArray();
        gen.writeFieldName('deletedTriggers');
        gen.writeStartArray();
        for(String trg: result.deletedTriggers) {
            gen.writeString(trg);
        }
        gen.writeEndArray();
        gen.writeFieldName('managedTriggers');
        gen.writeStartArray();
        for(String trg: result.managedTriggers) {
            gen.writeString(trg);
        }
        gen.writeEndArray();
        gen.writeEndObject();
        //Basic trigger information tab data ends here

        //Duplicated events tab data starts
        gen.writeFieldName('duplicatedEvents');
        gen.writeStartArray();
        for(ApexTriggerAnalyzerResults.EventDuplicate dup: result.eventDuplicates) {
            gen.writeStartObject();
            gen.writeStringField('eventName', dup.eventName);
            gen.writeFieldName('triggerName');
            gen.writeStartArray();
            for(String trg: dup.presentInTriggers) {
                gen.writeString(trg);
            }
            gen.writeEndArray();
            gen.writeEndObject();
        }
        gen.writeEndArray();
        //Duplicated events tab data ends

        //LoopDMLs start here
        gen.writeFieldName('loopDMLs');
        gen.writeStartArray();
        for(ApexTriggerAnalyzerResults.LoopDML loopDml: result.loopDmls) {
            for(Integer lineNumber : loopDml.dmlStatements.keySet()) {
                gen.writeStartObject();
                String statement = loopDml.dmlStatements.get(lineNumber);
                gen.writeStringField('statement', statement);
                gen.writeStringField('statementType', (statement.toLowerCase().contains('select') || statement.toLowerCase().contains('database.query') ? 'SOQL' : 'DML'));
                gen.writeStringField('triggerName', loopDml.triggerName);
                gen.writeNumberField('lineNumber', lineNumber);
                gen.writeEndObject();
            }
        }
        gen.writeEndArray();
        //LoopDMLs end here

        //HardCoded Ids start here
        gen.writeFieldName('hardcodedIds');
        gen.writeStartArray();
        for(ApexTriggerAnalyzerResults.HardCodedId hardcodedId: result.hardCodedIds) {
            for(Integer lineNumber : hardcodedId.hardCodedIds.keySet()) {
                gen.writeStartObject();
                gen.writeStringField('id', hardcodedId.hardCodedIds.get(lineNumber));
                gen.writeStringField('triggerName', hardcodedId.triggerName);
                gen.writeNumberField('lineNumber', lineNumber);
                gen.writeEndObject();
            }
        }
        gen.writeEndArray();
        //HardCoded Ids end here

        //SOQLs stats
        gen.writeFieldName('soqlStatistics');
        gen.writeStartArray();
        for(ApexTriggerAnalyzerResults.SoqlStatistics soqlStat : result.soqlStatistics) {
            gen.writeStartObject();
            gen.writeStringField('triggerName', soqlStat.triggerName);
            gen.writeNumberField('soqlCount', soqlStat.soqlQueryCount);
            gen.writeNumberField('soqlWithWhereCount', soqlStat.soqlQueriesWithWhereClauseCount);
            gen.writeNumberField('soqlWithoutWhereCount', soqlStat.soqlQueriesWithoutWhereClauseCount);
            gen.writeEndObject();
        }
        gen.writeEndArray();
        //SOQLs stats end
        
        gen.writeEndObject();
    }
}