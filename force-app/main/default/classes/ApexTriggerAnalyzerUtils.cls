public with sharing class ApexTriggerAnalyzerUtils {
    public ApexTriggerAnalyzerUtils() {

    }

    public static String removeCommentsFromCode(String code) {
        Integer n = code.length(); 
        String result = ''; 
  
        // Flags to indicate that single line and multpile line comments 
        // have started or not. 
        Boolean singleLineComment = false; 
        Boolean multiLineComment = false; 

        // Traverse the given program 
        for (Integer i = 0; i < n; i++) 
        { 
            // If single line comment flag is on, then check for end of it 
            if (singleLineComment == true && code.subString(i, i + 1) == '\n') {
                singleLineComment = false; 
            }

            // If multiple line comment is on, then check for end of it 
            else if  (multiLineComment == true && code.subString(i, i + 2)== '*/') {
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
}
