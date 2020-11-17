public with sharing class ApexTriggerAnalyzerUtils {
    public ApexTriggerAnalyzerUtils() {

    }

    public static Map<String, String> removeCommentedCodeFromTrigger(List<ApexTrigger> apexTriggers, Boolean preserveNewLines){
        String triggerbody;
        Map<String, String> triggerNamesWithBody = new Map<String, String>();
        
        if(apexTriggers != null || !apexTriggers.isEmpty()){
            for(ApexTrigger trig : apexTriggers){
                if(trig.body == '(hidden)'){
                    triggerNamesWithBody.put(trig.Name , 'Managed Package');
                } else{
                    triggerbody =  trig.body;
                    List<String> lengthOfBody = triggerBody.split('\n');

                    //Multi Line Comment
                    if(triggerbody.contains('/*')){
                        Integer count = triggerbody.countMatches('/*');
                        for(Integer i = 0; i < count; i++){
                            String removedpart = triggerbody.substringBetween('/*', '*/');
                            if(preserveNewLines) {
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
                Matcher newLineMatcher = newLineDetectionPattern.matcher(tempStr);

                Integer lineNumber = 1;
                while(newLineMatcher.find()) {
                    lineNumber++;
                }

                if(!returnMap.containsKey(lineNumber)) {
                    if(!statement.toUpperCase().contains('DATABASE')) {
                        statement = statement.replaceAll(']', '');
                    }
                    statement = statement.replaceAll('\n', ' ');
                    returnMap.put(lineNumber, statement);
                }
            }
        }

        return returnMap;
    }
 
    public static List<Integer> getLineNumberOfTrigger(String triggerBody, String hardcodedId){
        List<Integer> lineNumbersList = new List<Integer>();
        List<String> splitByLine = new List<String>();
        splitByLine = triggerBody.split('\n');
        system.debug('splitByLine'+splitByLine);
        system.debug('splitByLine'+splitByLine.size());
        
        Integer linenumber = 0;
        for(String line : splitByLine){
            linenumber++;
            if(line.contains(hardcodedId)) {
                lineNumbersList.add(linenumber);
            }
        }
        return lineNumbersList;
    }
    
    public static String getJsonReport(List<ApexTriggerAnalyzerResults> results) {
        String finalStr = '[';
        for(ApexTriggerAnalyzerResults result: results) {
            finalStr += (result.generateJSON(result) + ',\n');
        }
        finalStr = finalStr.substring(0, finalStr.length() - 2);
        finalStr += ']';
        return finalStr;
    }
}