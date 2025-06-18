/**
 * @description Service class for integrating with external salary data APIs
 * @author Temitayo Oluwalade
 * @date 2024
 */
public with sharing class SalaryDataAPIService {
    
    // API Configuration (in production, store in Custom Settings or Custom Metadata)
    private static final String BASE_URL = 'https://api.salarydata.com/v1';
    private static final String API_KEY = 'your_api_key_here'; // Use Named Credentials in production
    private static final Integer TIMEOUT = 30000; // 30 seconds
    private static final Integer RETRY_ATTEMPTS = 3;
    
    /**
     * @description Gets salary data for a specific position and location
     * @param positionTitle The job position title
     * @param location The job location (city, state)
     * @param experienceLevel Experience level (entry, mid, senior)
     * @return SalaryDataResponse with market data
     */
    public static SalaryDataResponse getSalaryData(String positionTitle, String location, String experienceLevel) {
        if (String.isBlank(positionTitle)) {
            throw new SalaryDataException('Position title is required');
        }
        
        try {
            // Build the API request
            HttpRequest request = buildSalaryDataRequest(positionTitle, location, experienceLevel);
            
            // Execute with retry logic
            HttpResponse response = executeWithRetry(request);
            
            // Parse and return the response
            return parseSalaryDataResponse(response);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching salary data: ' + e.getMessage());
            throw new SalaryDataException('Failed to fetch salary data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets bulk salary data for multiple positions
     * @param requests List of salary data requests
     * @return List of SalaryDataResponse objects
     */
    public static List<SalaryDataResponse> getBulkSalaryData(List<SalaryDataRequest> requests) {
        List<SalaryDataResponse> responses = new List<SalaryDataResponse>();
        
        if (requests == null || requests.isEmpty()) {
            return responses;
        }
        
        try {
            // Build bulk request
            HttpRequest request = buildBulkSalaryDataRequest(requests);
            
            // Execute request
            HttpResponse response = executeWithRetry(request);
            
            // Parse bulk response
            responses = parseBulkSalaryDataResponse(response);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching bulk salary data: ' + e.getMessage());
            // Return empty list rather than throwing exception for bulk operations
        }
        
        return responses;
    }
    
    /**
     * @description Gets trending salary data for market analysis
     * @param industry The industry sector
     * @param timeframe Timeframe for trends (3m, 6m, 1y)
     * @return SalaryTrendResponse with trend data
     */
    public static SalaryTrendResponse getSalaryTrends(String industry, String timeframe) {
        try {
            HttpRequest request = buildTrendRequest(industry, timeframe);
            HttpResponse response = executeWithRetry(request);
            return parseTrendResponse(response);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching salary trends: ' + e.getMessage());
            throw new SalaryDataException('Failed to fetch salary trends: ' + e.getMessage());
        }
    }
    
    /**
     * @description Builds HTTP request for salary data
     * @param positionTitle Job position
     * @param location Job location
     * @param experienceLevel Experience level
     * @return Configured HttpRequest
     */
    private static HttpRequest buildSalaryDataRequest(String positionTitle, String location, String experienceLevel) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(BASE_URL + '/salary-data');
        request.setMethod('GET');
        request.setTimeout(TIMEOUT);
        
        // Set headers
        request.setHeader('Authorization', 'Bearer ' + API_KEY);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        
        // Build query parameters
        String queryParams = buildQueryParams(new Map<String, String>{
            'position' => EncodingUtil.urlEncode(positionTitle, 'UTF-8'),
            'location' => EncodingUtil.urlEncode(location, 'UTF-8'),
            'experience' => EncodingUtil.urlEncode(experienceLevel, 'UTF-8'),
            'format' => 'json'
        });
        
        request.setEndpoint(request.getEndpoint() + '?' + queryParams);
        
        return request;
    }
    
    /**
     * @description Builds HTTP request for bulk salary data
     * @param requests List of salary data requests
     * @return Configured HttpRequest
     */
    private static HttpRequest buildBulkSalaryDataRequest(List<SalaryDataRequest> requests) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(BASE_URL + '/salary-data/bulk');
        request.setMethod('POST');
        request.setTimeout(TIMEOUT);
        
        // Set headers
        request.setHeader('Authorization', 'Bearer ' + API_KEY);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        
        // Build request body
        Map<String, Object> requestBody = new Map<String, Object>{
            'requests' => requests
        };
        
        request.setBody(JSON.serialize(requestBody));
        
        return request;
    }
    
    /**
     * @description Builds HTTP request for trend data
     * @param industry Industry sector
     * @param timeframe Trend timeframe
     * @return Configured HttpRequest
     */
    private static HttpRequest buildTrendRequest(String industry, String timeframe) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(BASE_URL + '/trends');
        request.setMethod('GET');
        request.setTimeout(TIMEOUT);
        
        // Set headers
        request.setHeader('Authorization', 'Bearer ' + API_KEY);
        request.setHeader('Content-Type', 'application/json');
        
        // Build query parameters
        String queryParams = buildQueryParams(new Map<String, String>{
            'industry' => EncodingUtil.urlEncode(industry, 'UTF-8'),
            'timeframe' => timeframe
        });
        
        request.setEndpoint(request.getEndpoint() + '?' + queryParams);
        
        return request;
    }
    
    /**
     * @description Executes HTTP request with retry logic
     * @param request HttpRequest to execute
     * @return HttpResponse
     */
    private static HttpResponse executeWithRetry(HttpRequest request) {
        Http http = new Http();
        HttpResponse response;
        Integer attempts = 0;
        
        while (attempts < RETRY_ATTEMPTS) {
            attempts++;
            
            try {
                response = http.send(request);
                
                if (response.getStatusCode() == 200) {
                    return response;
                } else if (response.getStatusCode() >= 500 && attempts < RETRY_ATTEMPTS) {
                    // Retry on server errors
                    System.debug('Server error, retrying... Attempt ' + attempts);
                    continue;
                } else {
                    throw new SalaryDataException('API Error: ' + response.getStatusCode() + ' - ' + response.getBody());
                }
                
            } catch (CalloutException e) {
                if (attempts < RETRY_ATTEMPTS) {
                    System.debug('Callout exception, retrying... Attempt ' + attempts);
                    continue;
                } else {
                    throw e;
                }
            }
        }
        
        throw new SalaryDataException('Failed after ' + RETRY_ATTEMPTS + ' attempts');
    }
    
    /**
     * @description Parses salary data API response
     * @param response HttpResponse from API
     * @return SalaryDataResponse object
     */
    private static SalaryDataResponse parseSalaryDataResponse(HttpResponse response) {
        try {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            if (responseData.containsKey('error')) {
                throw new SalaryDataException('API Error: ' + responseData.get('error'));
            }
            
            Map<String, Object> salaryData = (Map<String, Object>) responseData.get('salary_data');
            
            return new SalaryDataResponse(
                (Decimal) salaryData.get('min_salary'),
                (Decimal) salaryData.get('max_salary'),
                (Decimal) salaryData.get('median_salary'),
                (Decimal) salaryData.get('percentile_75'),
                (String) salaryData.get('currency'),
                (String) responseData.get('data_source'),
                Date.valueOf((String) responseData.get('last_updated'))
            );
            
        } catch (Exception e) {
            throw new SalaryDataException('Failed to parse API response: ' + e.getMessage());
        }
    }
    
    /**
     * @description Parses bulk salary data API response
     * @param response HttpResponse from API
     * @return List of SalaryDataResponse objects
     */
    private static List<SalaryDataResponse> parseBulkSalaryDataResponse(HttpResponse response) {
        List<SalaryDataResponse> responses = new List<SalaryDataResponse>();
        
        try {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> results = (List<Object>) responseData.get('results');
            
            for (Object result : results) {
                Map<String, Object> resultData = (Map<String, Object>) result;
                Map<String, Object> salaryData = (Map<String, Object>) resultData.get('salary_data');
                
                if (salaryData != null) {
                    responses.add(new SalaryDataResponse(
                        (Decimal) salaryData.get('min_salary'),
                        (Decimal) salaryData.get('max_salary'),
                        (Decimal) salaryData.get('median_salary'),
                        (Decimal) salaryData.get('percentile_75'),
                        (String) salaryData.get('currency'),
                        (String) resultData.get('data_source'),
                        Date.valueOf((String) resultData.get('last_updated'))
                    ));
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to parse bulk API response: ' + e.getMessage());
        }
        
        return responses;
    }
    
    /**
     * @description Parses trend data API response
     * @param response HttpResponse from API
     * @return SalaryTrendResponse object
     */
    private static SalaryTrendResponse parseTrendResponse(HttpResponse response) {
        try {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> trendData = (Map<String, Object>) responseData.get('trend_data');
            
            return new SalaryTrendResponse(
                (String) trendData.get('industry'),
                (String) trendData.get('trend_direction'),
                (Decimal) trendData.get('growth_percentage'),
                (List<Object>) trendData.get('monthly_data')
            );
            
        } catch (Exception e) {
            throw new SalaryDataException('Failed to parse trend response: ' + e.getMessage());
        }
    }
    
    /**
     * @description Builds query parameter string
     * @param params Map of parameter key-value pairs
     * @return URL-encoded query string
     */
    private static String buildQueryParams(Map<String, String> params) {
        List<String> paramList = new List<String>();
        
        for (String key : params.keySet()) {
            if (String.isNotBlank(params.get(key))) {
                paramList.add(key + '=' + params.get(key));
            }
        }
        
        return String.join(paramList, '&');
    }
    
    /**
     * @description Custom exception for salary data API errors
     */
    public class SalaryDataException extends Exception {}
    
    /**
     * @description Request wrapper for salary data API calls
     */
    public class SalaryDataRequest {
        public String positionTitle;
        public String location;
        public String experienceLevel;
        
        public SalaryDataRequest(String position, String loc, String experience) {
            this.positionTitle = position;
            this.location = loc;
            this.experienceLevel = experience;
        }
    }
    
    /**
     * @description Response wrapper for salary data
     */
    public class SalaryDataResponse {
        public Decimal minSalary;
        public Decimal maxSalary;
        public Decimal medianSalary;
        public Decimal percentile75;
        public String currencyCode;
        public String dataSource;
        public Date lastUpdated;
        
        public SalaryDataResponse(Decimal min, Decimal max, Decimal median, Decimal p75, 
                                 String curr, String source, Date updated) {
            this.minSalary = min;
            this.maxSalary = max;
            this.medianSalary = median;
            this.percentile75 = p75;
            this.currencyCode = curr;
            this.dataSource = source;
            this.lastUpdated = updated;
        }
    }
    
    /**
     * @description Response wrapper for salary trend data
     */
    public class SalaryTrendResponse {
        public String industry;
        public String trendDirection;
        public Decimal growthPercentage;
        public List<Object> monthlyData;
        
        public SalaryTrendResponse(String ind, String direction, Decimal growth, List<Object> data) {
            this.industry = ind;
            this.trendDirection = direction;
            this.growthPercentage = growth;
            this.monthlyData = data;
        }
    }
}
