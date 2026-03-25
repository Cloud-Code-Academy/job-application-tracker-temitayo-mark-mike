/**
 * @description Base class for REST API integrations providing common functionality
 * @author Learning Journey
 * @date 2025-01-08
 */
public abstract inherited sharing class BaseApiService {
    
    // Constants for HTTP methods and status codes
    public static final String HTTP_GET = 'GET';
    public static final String HTTP_POST = 'POST';
    public static final String HTTP_PUT = 'PUT';
    public static final String HTTP_DELETE = 'DELETE';
    public static final String HTTP_PATCH = 'PATCH';
    
    public static final Integer HTTP_OK = 200;
    public static final Integer HTTP_CREATED = 201;
    public static final Integer HTTP_NO_CONTENT = 204;
    public static final Integer HTTP_BAD_REQUEST = 400;
    public static final Integer HTTP_UNAUTHORIZED = 401;
    public static final Integer HTTP_FORBIDDEN = 403;
    public static final Integer HTTP_NOT_FOUND = 404;
    public static final Integer HTTP_TOO_MANY_REQUESTS = 429;
    public static final Integer HTTP_INTERNAL_SERVER_ERROR = 500;
    
    // Default timeout and retry settings
    private static final Integer DEFAULT_TIMEOUT = 30000; // 30 seconds
    private static final Integer MAX_RETRY_ATTEMPTS = 3;
    private static final Integer RETRY_DELAY_MS = 1000; // 1 second
    
    /**
     * @description Wrapper class for API responses
     */
    public class ApiResponse {
        public Boolean isSuccess { get; set; }
        public Integer statusCode { get; set; }
        public String body { get; set; }
        public String errorMessage { get; set; }
        public Map<String, String> headers { get; set; }
        public Long responseTime { get; set; }
        
        public ApiResponse() {
            this.headers = new Map<String, String>();
            this.isSuccess = false;
        }
    }
    
    /**
     * @description Configuration class for API requests
     */
    public class ApiRequest {
        public String endpoint { get; set; }
        public String method { get; set; }
        public String body { get; set; }
        public Map<String, String> headers { get; set; }
        public Map<String, String> parameters { get; set; }
        public Integer timeout { get; set; }
        public Boolean enableRetry { get; set; }
        
        public ApiRequest() {
            this.method = HTTP_GET;
            this.headers = new Map<String, String>();
            this.parameters = new Map<String, String>();
            this.timeout = DEFAULT_TIMEOUT;
            this.enableRetry = true;
        }
    }
    
    /**
     * @description Make HTTP callout with retry logic and error handling
     * @param request ApiRequest configuration
     * @return ApiResponse with results
     */
    protected ApiResponse makeCallout(ApiRequest request) {
        ApiResponse response = new ApiResponse();
        Long startTime = System.currentTimeMillis();
        
        try {
            // Validate request
            validateRequest(request);
            
            // Build HTTP request
            HttpRequest httpRequest = buildHttpRequest(request);
            
            // Execute with retry logic
            HttpResponse httpResponse = executeWithRetry(httpRequest, request.enableRetry);
            
            // Process response
            response = processHttpResponse(httpResponse);
            
        } catch (Exception e) {
            response.isSuccess = false;
            response.errorMessage = 'Callout failed: ' + e.getMessage();
            response.statusCode = 0;
            
            // Log error for debugging
            System.debug(LoggingLevel.ERROR, 'API Callout Error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
        }
        
        response.responseTime = System.currentTimeMillis() - startTime;
        
        // Log callout details
        logCallout(request, response);
        
        return response;
    }
    
    /**
     * @description Validate API request configuration
     * @param request ApiRequest to validate
     */
    private void validateRequest(ApiRequest request) {
        if (String.isBlank(request.endpoint)) {
            throw new ApiException('Endpoint URL is required');
        }
        
        if (String.isBlank(request.method)) {
            throw new ApiException('HTTP method is required');
        }
        
        // Validate URL format
        if (!request.endpoint.startsWithIgnoreCase('http://') && 
            !request.endpoint.startsWithIgnoreCase('https://')) {
            throw new ApiException('Invalid endpoint URL format');
        }
    }
    
    /**
     * @description Build HttpRequest from ApiRequest configuration
     * @param request ApiRequest configuration
     * @return Configured HttpRequest
     */
    private HttpRequest buildHttpRequest(ApiRequest request) {
        HttpRequest httpRequest = new HttpRequest();
        
        // Set basic properties
        httpRequest.setMethod(request.method);
        httpRequest.setTimeout(request.timeout);
        
        // Build endpoint with parameters
        String endpoint = buildEndpointWithParameters(request.endpoint, request.parameters);
        httpRequest.setEndpoint(endpoint);
        
        // Set headers
        for (String headerName : request.headers.keySet()) {
            httpRequest.setHeader(headerName, request.headers.get(headerName));
        }
        
        // Set default headers if not provided
        if (!request.headers.containsKey('Content-Type')) {
            httpRequest.setHeader('Content-Type', 'application/json');
        }
        
        if (!request.headers.containsKey('Accept')) {
            httpRequest.setHeader('Accept', 'application/json');
        }
        
        // Set body for POST/PUT/PATCH requests
        if (String.isNotBlank(request.body) && 
            (request.method == HTTP_POST || request.method == HTTP_PUT || request.method == HTTP_PATCH)) {
            httpRequest.setBody(request.body);
        }
        
        return httpRequest;
    }
    
    /**
     * @description Build endpoint URL with query parameters
     * @param baseEndpoint Base URL
     * @param parameters Query parameters
     * @return Complete endpoint URL
     */
    private String buildEndpointWithParameters(String baseEndpoint, Map<String, String> parameters) {
        if (parameters == null || parameters.isEmpty()) {
            return baseEndpoint;
        }
        
        List<String> paramStrings = new List<String>();
        for (String key : parameters.keySet()) {
            String value = parameters.get(key);
            if (String.isNotBlank(value)) {
                paramStrings.add(EncodingUtil.urlEncode(key, 'UTF-8') + '=' + 
                               EncodingUtil.urlEncode(value, 'UTF-8'));
            }
        }
        
        if (!paramStrings.isEmpty()) {
            String separator = baseEndpoint.contains('?') ? '&' : '?';
            return baseEndpoint + separator + String.join(paramStrings, '&');
        }
        
        return baseEndpoint;
    }
    
    /**
     * @description Execute HTTP request with retry logic
     * @param httpRequest HttpRequest to execute
     * @param enableRetry Whether to enable retry on failure
     * @return HttpResponse
     */
    private HttpResponse executeWithRetry(HttpRequest httpRequest, Boolean enableRetry) {
        Http http = new Http();
        HttpResponse httpResponse;
        Integer attempts = 0;
        
        while (attempts < MAX_RETRY_ATTEMPTS) {
            attempts++;
            
            try {
                httpResponse = http.send(httpRequest);
                
                // Check if retry is needed
                if (shouldRetry(httpResponse) && enableRetry && attempts < MAX_RETRY_ATTEMPTS) {
                    System.debug('Retrying request, attempt ' + attempts + ' of ' + MAX_RETRY_ATTEMPTS);
                    
                    // Wait before retry (simple delay)
                    Long startWait = System.currentTimeMillis();
                    while (System.currentTimeMillis() - startWait < RETRY_DELAY_MS) {
                        // Simple delay loop
                    }
                    continue;
                }
                
                break;
                
            } catch (Exception e) {
                if (attempts >= MAX_RETRY_ATTEMPTS || !enableRetry) {
                    throw e;
                }
                
                System.debug('Request failed, retrying: ' + e.getMessage());
                
                // Wait before retry
                Long startWait = System.currentTimeMillis();
                while (System.currentTimeMillis() - startWait < RETRY_DELAY_MS) {
                    // Simple delay loop
                }
            }
        }
        
        return httpResponse;
    }
    
    /**
     * @description Determine if request should be retried based on response
     * @param response HttpResponse to check
     * @return True if should retry
     */
    private Boolean shouldRetry(HttpResponse response) {
        Integer statusCode = response.getStatusCode();
        
        // Retry on server errors and rate limiting
        return statusCode >= 500 || statusCode == HTTP_TOO_MANY_REQUESTS;
    }
    
    /**
     * @description Process HttpResponse into ApiResponse
     * @param httpResponse HttpResponse to process
     * @return Processed ApiResponse
     */
    private ApiResponse processHttpResponse(HttpResponse httpResponse) {
        ApiResponse response = new ApiResponse();
        
        response.statusCode = httpResponse.getStatusCode();
        response.body = httpResponse.getBody();
        
        // Copy headers
        for (String headerName : httpResponse.getHeaderKeys()) {
            response.headers.put(headerName, httpResponse.getHeader(headerName));
        }
        
        // Determine success based on status code
        response.isSuccess = (response.statusCode >= 200 && response.statusCode < 300);
        
        // Set error message for failed requests
        if (!response.isSuccess) {
            response.errorMessage = 'HTTP ' + response.statusCode + ': ' + getStatusMessage(response.statusCode);
            
            // Try to extract error details from response body
            if (String.isNotBlank(response.body)) {
                try {
                    Map<String, Object> errorData = (Map<String, Object>) JSON.deserializeUntyped(response.body);
                    if (errorData.containsKey('error')) {
                        response.errorMessage += ' - ' + String.valueOf(errorData.get('error'));
                    } else if (errorData.containsKey('message')) {
                        response.errorMessage += ' - ' + String.valueOf(errorData.get('message'));
                    }
                } catch (Exception e) {
                    // If JSON parsing fails, use raw body
                    response.errorMessage += ' - ' + response.body;
                }
            }
        }
        
        return response;
    }
    
    /**
     * @description Get human-readable status message for HTTP status code
     * @param statusCode HTTP status code
     * @return Status message
     */
    private String getStatusMessage(Integer statusCode) {
        switch on statusCode {
            when 400 { return 'Bad Request'; }
            when 401 { return 'Unauthorized'; }
            when 403 { return 'Forbidden'; }
            when 404 { return 'Not Found'; }
            when 429 { return 'Too Many Requests'; }
            when 500 { return 'Internal Server Error'; }
            when 502 { return 'Bad Gateway'; }
            when 503 { return 'Service Unavailable'; }
            when 504 { return 'Gateway Timeout'; }
            when else { return 'Unknown Error'; }
        }
    }
    
    /**
     * @description Log callout details for monitoring and debugging
     * @param request ApiRequest that was made
     * @param response ApiResponse that was received
     */
    private void logCallout(ApiRequest request, ApiResponse response) {
        String logLevel = response.isSuccess ? 'INFO' : 'ERROR';
        
        System.debug('=== API Callout Log ===');
        System.debug('Endpoint: ' + request.endpoint);
        System.debug('Method: ' + request.method);
        System.debug('Status Code: ' + response.statusCode);
        System.debug('Success: ' + response.isSuccess);
        System.debug('Response Time: ' + response.responseTime + 'ms');
        
        if (!response.isSuccess) {
            System.debug('Error: ' + response.errorMessage);
        }
        
        if (String.isNotBlank(response.body) && response.body.length() < 1000) {
            System.debug('Response Body: ' + response.body);
        }
    }
    
    /**
     * @description Parse JSON response body into Map
     * @param jsonBody JSON string to parse
     * @return Parsed Map or null if parsing fails
     */
    protected Map<String, Object> parseJsonResponse(String jsonBody) {
        if (String.isBlank(jsonBody)) {
            return null;
        }
        
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to parse JSON response: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Get nested value from parsed JSON response
     * @param data Parsed JSON data
     * @param path Dot-separated path to value (e.g., 'data.company.name')
     * @return Value at path or null if not found
     */
    protected Object getNestedValue(Map<String, Object> data, String path) {
        if (data == null || String.isBlank(path)) {
            return null;
        }
        
        List<String> pathParts = path.split('\\.');
        Object current = data;
        
        for (String part : pathParts) {
            if (current instanceof Map<String, Object>) {
                Map<String, Object> currentMap = (Map<String, Object>) current;
                current = currentMap.get(part);
            } else {
                return null;
            }
        }
        
        return current;
    }
    
    /**
     * @description Custom exception class for API errors
     */
    public class ApiException extends Exception {}
}