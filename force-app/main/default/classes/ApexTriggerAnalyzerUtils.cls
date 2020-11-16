public with sharing class ApexTriggerAnalyzerUtils {
    public ApexTriggerAnalyzerUtils() {

    }

    public static String removeCommentsFromCode(String code) {
        Integer n = code.length(); 
        String result = ''; 
        Boolean singleLineComment = false; 
        Boolean multiLineComment = false; 

        for (Integer i = 0; i < n; i++) 
        { 
            // If single line comment flag is on, then check for end of it 
            if (singleLineComment == true && code.subString(i, i + 1) == '\n') {
                singleLineComment = false; 
            }

            // If multiple line comment is on, then check for end of it 
            else if  (multiLineComment == true && code.subString(i, i + 2) == '*/') {
                multiLineComment = false;
                i++;
                if(i >= n)
                    break;
            }

            // If this character is in a comment, replace with empty character
            else if (singleLineComment || multiLineComment) {
                result += ' ';
            }

            // Check for beginning of comments and set the appropriate flags 
            else if ((i + 2) <= n && code.subString(i, i + 2) == '//') {
                singleLineComment = true;
                i++;
                if(i >= n)
                    break;
            }
            else if ((i + 2) <= n && code.subString(i, i + 2) == '/*') {
                multiLineComment = true;
                i++; 
                if(i >= n)
                    break;
            }
            // If current character is a non-comment character, append it to result 
            else {
                result += code.subString(i, i + 1); 
            }
        } 
        return result; 
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
    
    public static Map<String, String> removeCommentedCodeFromTrigger(List<ApexTrigger> apexTriggers){
        
        String triggerbody;
        Map<String, String> triggerNamesWithBody = new Map<String, String>();
        
        if(apexTriggers != null || !apexTriggers.isEmpty()){
            for(ApexTrigger trig : apexTriggers){
                if(trig.body == '(hidden)'){
                    triggerNamesWithBody.put(trig.Name , 'Managed Package');
                    
                }else{
                    triggerbody =  trig.body;
                    List<String> lengthOfBody = triggerBody.split('\n');
                    system.debug('Apex Triggers****'+triggerbody);
                    system.debug('Apex Triggers****'+lengthOfBody.size());
                    //Multi Line Comment
                    if(triggerbody.contains('/*')){
                        Integer count = triggerbody.countMatches('/*');
                        for(Integer i = 0; i < count; i++){
                            String removedpart = triggerbody.substringBetween('/*', '*/');
                            triggerbody = triggerbody.remove('/*'+removedpart+'*/');
                            
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
}