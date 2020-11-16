public with sharing class ApexTriggerAnalyzerUtils {
    public ApexTriggerAnalyzerUtils() {

    }

    public static Map<String, String> removeCommentedCodeFromTrigger(List<ApexTrigger> apexTriggers, Boolean replaceMultiCommentsWithSpace){
        String triggerbody;
        Map<String, String> triggerNamesWithBody = new Map<String, String>();
        
        if(apexTriggers != null || !apexTriggers.isEmpty()){
            for(ApexTrigger trig : apexTriggers){
                if(trig.body == '(hidden)'){
                    triggerNamesWithBody.put(trig.Name , 'Managed Package');
                }else{
                    triggerbody =  trig.body;
                    List<String> lengthOfBody = triggerBody.split('\n');

                    //Multi Line Comment
                    if(triggerbody.contains('/*')){
                        Integer count = triggerbody.countMatches('/*');
                        for(Integer i = 0; i < count; i++){
                            String removedpart = triggerbody.substringBetween('/*', '*/');
                            if(replaceMultiCommentsWithSpace) {
                                //Generate blank string
                                String blankReplacementString = '';
                                for(Integer j = 0; j < removedpart.length(); j++) {
                                    blankReplacementString += (removedpart.substring(j, j + 1) == '\n' ? '\n' : ' ');
                                }
                                triggerbody = triggerbody.replace('/*'+removedpart+'*/', ('  ' + blankReplacementString + '  '));
                            } else {
                                triggerbody = triggerbody.remove('/*'+removedpart+'*/');
                            }
                        }
                    }
                    
                    //Single Line Comment
                    if(triggerbody.contains('//')){
                        Integer count2 = triggerbody.countMatches('//');
                        for(Integer i = 0; i < count2; i++){
                            String removedpart = triggerbody.substringBetween('//', '\n');
                            triggerbody = triggerbody.remove('//'+removedpart);
                        }
                    }
                    if(triggerbody != null || triggerbody != ''){
                        triggerNamesWithBody.put(trig.Name , triggerbody); 
                    }
                }
            }
        }
        return triggerNamesWithBody;
    }

    public static Map<Integer, String> detectLoopsFromCode(String code) {
        Map<Integer,String> loopPositionMap = new Map<Integer,String>();
        Boolean discardNextWhile = false;

        Pattern loopDetectionPattern = pattern.compile('(?i)\\b(for|do|while)\\b');
        Matcher loopMatcher = loopDetectionPattern.matcher(code);

        while(loopMatcher.find()) {
            Integer position = loopMatcher.end();
            String loopType = loopMatcher.group().toLowerCase();
            if(!discardNextWhile) {
                loopPositionMap.put(position, loopType);
            }
            discardNextWhile = loopType == 'do'; //Discards the next detected while because do loop is detected 
        }
        return loopPositionMap;
    }

    public static List<String> getLoopBodies(Map<Integer, String> loopPositionMap, String code) {
        List<String> loopBodies = new List<String>();
        for(Integer position : loopPositionMap.keySet()) {
            Integer initPosition = position;
            Integer currentPosition = position;

            while((currentPosition < code.length())) {
                //if a semicolon is detected before { is detected then it means
                //the loop doesn't use parenthesis. In that case the loop only contains a single line
                if(code.substring(currentPosition, currentPosition + 1) == ';') {
                    loopBodies.add(code.substring(initPosition, currentPosition));
                    break;
                }

                if(code.substring(currentPosition, currentPosition + 1) == '{') { //Opening parenthesis found, find matching closing parenthesis
                    Integer openingCount = 1;
                    Integer tempIndex = (currentPosition + 1);
                    while(openingCount != 0) {
                        if(code.substring(tempIndex, tempIndex + 1) == '{') {
                            openingCount++;
                        }
                        if(code.substring(tempIndex, tempIndex + 1) == '}') {
                            openingCount--;
                        }
                        tempIndex++;
                    }
                    loopBodies.add(code.substring(currentPosition, tempIndex));
                    currentPosition += tempIndex;
                }
                currentPosition++;
            }
        }
        return loopBodies;
    }

    public static Map<Integer, String> getQueryStatementsFromCode(List<String> loopBodies, String fullBody) {
        List<String> lines = fullBody.split('\n');
        Map<Integer, String> returnMap = new Map<Integer, String>();

        for(String loopBody: loopBodies) {
            Pattern loopDetectionPattern = pattern.compile('(?i)\\b(select|insert|update|delete|upsert|undelete|Database.insert|Database.update|Database.delete|Database.upsert|Database.undelete)\\b');
            Matcher loopMatcher = loopDetectionPattern.matcher(loopBody);

            while(loopMatcher.find()) {
                Integer position = loopMatcher.start();
                String statement = '';
                do {
                    statement += loopBody.substring(position, position + 1);
                    position++;
                } while(loopBody.substring(position, position + 1) != ';');

                //Once statement is received, get the substring from full body
                Integer charIndex = fullBody.indexOf(statement);
                String tempStr = fullBody.substring(0, charIndex);

                Pattern newLineDetectionPattern = pattern.compile('\r\n|\r|\n');
                Matcher newLinematcher = newLineDetectionPattern.matcher(tempStr);

                Integer lineNumber = 1;
                while(newLinematcher.find()) {
                    lineNumber++;
                }

                if(!returnMap.containsKey(lineNumber)) {
                    statement = statement.replaceAll(']', '');
                    statement = statement.replaceAll('\n', ' ');
                    returnMap.put(lineNumber, statement);
                }
            }
        }

        return returnMap;
    }
    
     public static Map<String, String> getBodyFromTrigger(List<ApexTrigger> apexTriggers){
        
        String triggerbody;
        Map<String, String> triggerNamesWithBody = new Map<String, String>();
        
        if(apexTriggers != null || !apexTriggers.isEmpty()){
            for(ApexTrigger trig : apexTriggers){
                if(trig.body == '(hidden)'){
                    //do something
                    
                }else{
                    triggerbody =  trig.body;
                  
                    if(triggerbody != null || triggerbody != ''){
                        triggerNamesWithBody.put(trig.Name , triggerbody); 
                    }
                }
            } 
            
        }
        return triggerNamesWithBody;
    }
    
    public static Map<String, List<Integer>> getLineNumberOfTrigger(Map<String , List<String>> trigerBodyIdsMap, List<ApexTrigger> apexTriggers){
        Map<String, List<Integer>> idsWithLineNumbers = new Map<String, List<Integer>>();
        List<Integer> lineNumbersList = new List<Integer>();
        for(String body : trigerBodyIdsMap.keySet()){
            
            List<String> splitByLine = new List<String>();
            splitByLine = body.split('\n');
            system.debug('splitByLine'+splitByLine);
            system.debug('splitByLine'+splitByLine.size());
            for(Integer i = 0; i < trigerBodyIdsMap.get(body).size(); i++){
                Integer linenumber;
                for(String line : splitByLine){
                    
                    if(line.contains(trigerBodyIdsMap.get(body)[i])){
                        linenumber = splitByLine.indexOf(line);
                        lineNumbersList.add(linenumber);
                    }
                }
                
                idsWithLineNumbers.put(trigerBodyIdsMap.get(body)[i], lineNumbersList);
            }
        }
        return idsWithLineNumbers;
    }

    public static String getJsonReport(List<ApexTriggerAnalyzerResults> results) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for(ApexTriggerAnalyzerResults result: results) {
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
                    gen.writeStringField('statement', loopDml.dmlStatements.get(lineNumber));
                    gen.writeStringField('triggerName', loopDml.triggerName);
                    gen.writeNumberField('lineNumber', lineNumber);
                    gen.writeEndObject();
                }
            }
            gen.writeEndArray();
            //LoopDMLs end here

            gen.writeEndObject();
        }
        gen.writeEndArray();
        return gen.getAsString();
    }
}