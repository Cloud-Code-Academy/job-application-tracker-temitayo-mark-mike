/**
 * Test class for HelloWorld Apex class
 * Demonstrates proper testing practices and deployment verification
 */
@isTest
public class HelloWorldTest {
    
    /**
     * Test the basic greeting method
     */
    @isTest
    static void testGetGreeting() {
        // Test
        String result = HelloWorld.getGreeting();
        
        // Verify
        Assert.areEqual('Hello World from Salesforce Apex!', result, 'Basic greeting should match expected message');
    }
    
    /**
     * Test personalized greeting with valid name
     */
    @isTest
    static void testGetPersonalizedGreetingWithName() {
        // Test
        String result = HelloWorld.getPersonalizedGreeting('Developer');
        
        // Verify
        Assert.areEqual('Hello Developer from Salesforce Apex!', result, 'Personalized greeting should include the provided name');
    }
    
    /**
     * Test personalized greeting with blank name
     */
    @isTest
    static void testGetPersonalizedGreetingWithBlankName() {
        // Test with null
        String resultNull = HelloWorld.getPersonalizedGreeting(null);
        String resultEmpty = HelloWorld.getPersonalizedGreeting('');
        String resultWhitespace = HelloWorld.getPersonalizedGreeting('   ');
        
        // Verify all blank inputs return basic greeting
        String expectedBasicGreeting = 'Hello World from Salesforce Apex!';
        Assert.areEqual(expectedBasicGreeting, resultNull, 'Null name should return basic greeting');
        Assert.areEqual(expectedBasicGreeting, resultEmpty, 'Empty name should return basic greeting');
        Assert.areEqual(expectedBasicGreeting, resultWhitespace, 'Whitespace name should return basic greeting');
    }
}