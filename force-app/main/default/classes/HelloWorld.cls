/**
 * Hello World Apex class for testing deployment workflow
 * This class demonstrates basic Apex functionality and deployment process
 */
public inherited sharing class HelloWorld {
    
    /**
     * Simple method that returns a greeting message
     * @return String greeting message
     */
    public static String getGreeting() {
        return 'Hello World from Salesforce Apex!';
    }
    
    /**
     * Method that demonstrates basic Apex logic
     * @param name The name to include in the greeting
     * @return String personalized greeting
     */
    public static String getPersonalizedGreeting(String name) {
        if (String.isBlank(name)) {
            return getGreeting();
        }
        return 'Hello ' + name + ' from Salesforce Apex!';
    }
}