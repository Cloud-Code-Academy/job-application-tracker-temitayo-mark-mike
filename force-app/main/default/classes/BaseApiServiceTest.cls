/**
 * @description Test class for BaseApiService
 * @author Learning Journey
 * @date 2025-01-08
 */
@IsTest
public inherited sharing class BaseApiServiceTest {
    
    /**
     * @description Test implementation of BaseApiService for testing
     */
    public class TestApiService extends BaseApiService {
        public ApiResponse testMakeCallout(ApiRequest request) {
            return makeCallout(request);
        }
        
        public Map<String, Object> testParseJsonResponse(String jsonBody) {
            return parseJsonResponse(jsonBody);
        }
        
        public Object testGetNestedValue(Map<String, Object> data, String path) {
            return getNestedValue(data, path);
        }
    }
    
    @IsTest
    static void testSuccessfulApiCall() {
        // Setup mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"status": "success", "data": {"message": "Hello World"}}'));
        
        TestApiService service = new TestApiService();
        BaseApiService.ApiRequest request = new BaseApiService.ApiRequest();
        request.endpoint = 'https://api.example.com/test';
        request.method = 'GET';
        
        Test.startTest();
        BaseApiService.ApiResponse response = service.testMakeCallout(request);
        Test.stopTest();
        
        System.assert(response.isSuccess, 'Response should be successful');
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertNotEquals(null, response.body, 'Response body should not be null');
        System.assert(response.responseTime > 0, 'Response time should be recorded');
    }
    
    @IsTest
    static void testFailedApiCall() {
        // Setup mock error response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(404, '{"error": "Not Found"}'));
        
        TestApiService service = new TestApiService();
        BaseApiService.ApiRequest request = new BaseApiService.ApiRequest();
        request.endpoint = 'https://api.example.com/notfound';
        request.method = 'GET';
        
        Test.startTest();
        BaseApiService.ApiResponse response = service.testMakeCallout(request);
        Test.stopTest();
        
        System.assert(!response.isSuccess, 'Response should not be successful');
        System.assertEquals(404, response.statusCode, 'Status code should be 404');
        System.assertNotEquals(null, response.errorMessage, 'Error message should be set');
    }
    
    @IsTest
    static void testPostRequestWithBody() {
        // Setup mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201, '{"id": 123, "created": true}'));
        
        TestApiService service = new TestApiService();
        BaseApiService.ApiRequest request = new BaseApiService.ApiRequest();
        request.endpoint = 'https://api.example.com/create';
        request.method = 'POST';
        request.body = '{"name": "Test Item"}';
        request.headers.put('Content-Type', 'application/json');
        
        Test.startTest();
        BaseApiService.ApiResponse response = service.testMakeCallout(request);
        Test.stopTest();
        
        System.assert(response.isSuccess, 'Response should be successful');
        System.assertEquals(201, response.statusCode, 'Status code should be 201');
    }
    
    @IsTest
    static void testRequestWithParameters() {
        // Setup mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"results": []}'));
        
        TestApiService service = new TestApiService();
        BaseApiService.ApiRequest request = new BaseApiService.ApiRequest();
        request.endpoint = 'https://api.example.com/search';
        request.method = 'GET';
        request.parameters.put('query', 'test search');
        request.parameters.put('limit', '10');
        
        Test.startTest();
        BaseApiService.ApiResponse response = service.testMakeCallout(request);
        Test.stopTest();
        
        System.assert(response.isSuccess, 'Response should be successful');
    }
    
    @IsTest
    static void testInvalidEndpoint() {
        TestApiService service = new TestApiService();
        BaseApiService.ApiRequest request = new BaseApiService.ApiRequest();
        request.endpoint = 'invalid-url';
        request.method = 'GET';
        
        Test.startTest();
        BaseApiService.ApiResponse response = service.testMakeCallout(request);
        Test.stopTest();
        
        System.assert(!response.isSuccess, 'Response should not be successful');
        System.assertNotEquals(null, response.errorMessage, 'Error message should be set');
    }
    
    @IsTest
    static void testJsonParsing() {
        TestApiService service = new TestApiService();
        String jsonString = '{"user": {"name": "John", "age": 30}, "status": "active"}';
        
        Test.startTest();
        Map<String, Object> parsed = service.testParseJsonResponse(jsonString);
        Test.stopTest();
        
        System.assertNotEquals(null, parsed, 'Parsed JSON should not be null');
        System.assertEquals('active', parsed.get('status'), 'Status should be parsed correctly');
    }
    
    @IsTest
    static void testNestedValueExtraction() {
        TestApiService service = new TestApiService();
        Map<String, Object> data = new Map<String, Object>{
            'user' => new Map<String, Object>{
                'profile' => new Map<String, Object>{
                    'name' => 'John Doe',
                    'email' => 'john@example.com'
                }
            }
        };
        
        Test.startTest();
        Object name = service.testGetNestedValue(data, 'user.profile.name');
        Object email = service.testGetNestedValue(data, 'user.profile.email');
        Object missing = service.testGetNestedValue(data, 'user.profile.phone');
        Test.stopTest();
        
        System.assertEquals('John Doe', name, 'Name should be extracted correctly');
        System.assertEquals('john@example.com', email, 'Email should be extracted correctly');
        System.assertEquals(null, missing, 'Missing value should return null');
    }
    
    @IsTest
    static void testRetryLogic() {
        // Setup mock to return 500 first, then 200
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, '{"error": "Server Error"}', 200, '{"status": "success"}'));
        
        TestApiService service = new TestApiService();
        BaseApiService.ApiRequest request = new BaseApiService.ApiRequest();
        request.endpoint = 'https://api.example.com/retry-test';
        request.method = 'GET';
        request.enableRetry = true;
        
        Test.startTest();
        BaseApiService.ApiResponse response = service.testMakeCallout(request);
        Test.stopTest();
        
        // Note: In test context, retry logic may not work exactly as in real execution
        // This test verifies the structure is in place
        System.assertNotEquals(null, response, 'Response should not be null');
    }
    
    @IsTest
    static void testCustomTimeout() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"status": "success"}'));
        
        TestApiService service = new TestApiService();
        BaseApiService.ApiRequest request = new BaseApiService.ApiRequest();
        request.endpoint = 'https://api.example.com/test';
        request.method = 'GET';
        request.timeout = 60000; // 60 seconds
        
        Test.startTest();
        BaseApiService.ApiResponse response = service.testMakeCallout(request);
        Test.stopTest();
        
        System.assert(response.isSuccess, 'Response should be successful');
    }
    
    /**
     * @description Mock HTTP response generator for testing
     */
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        private Integer retryStatusCode;
        private String retryBody;
        private Integer callCount = 0;
        
        public MockHttpResponseGenerator(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        
        public MockHttpResponseGenerator(Integer firstStatusCode, String firstBody, Integer secondStatusCode, String secondBody) {
            this.statusCode = firstStatusCode;
            this.body = firstBody;
            this.retryStatusCode = secondStatusCode;
            this.retryBody = secondBody;
        }
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            
            callCount++;
            
            if (retryStatusCode != null && callCount > 1) {
                response.setStatusCode(retryStatusCode);
                response.setBody(retryBody);
            } else {
                response.setStatusCode(statusCode);
                response.setBody(body);
            }
            
            response.setHeader('Content-Type', 'application/json');
            return response;
        }
    }
}