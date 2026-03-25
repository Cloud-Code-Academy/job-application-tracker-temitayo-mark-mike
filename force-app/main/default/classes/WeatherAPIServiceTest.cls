/**
 * @description Test class for WeatherAPIService
 * Demonstrates comprehensive API testing patterns including mocking
 * @author Learning Journey
 * @date 2025-01-08
 */
@IsTest
private inherited sharing class WeatherAPIServiceTest {
    
    /**
     * @description Mock HTTP callout class for testing
     */
    private class MockWeatherAPICallout implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private String endpoint;
        
        public MockWeatherAPICallout(Integer code, String body) {
            this.statusCode = code;
            this.responseBody = body;
        }
        
        public MockWeatherAPICallout(Integer code, String body, String endpointPattern) {
            this.statusCode = code;
            this.responseBody = body;
            this.endpoint = endpointPattern;
        }
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(this.statusCode);
            response.setBody(this.responseBody);
            response.setHeader('Content-Type', 'application/json');
            
            // Verify request properties in tests
            System.assert(request.getEndpoint().contains('api.openweathermap.org'), 
                         'Request should be made to OpenWeatherMap API');
            System.assertEquals('GET', request.getMethod(), 'Should use GET method');
            System.assert(request.getTimeout() > 0, 'Timeout should be set');
            
            return response;
        }
    }
    
    /**
     * @description Test successful weather data retrieval
     */
    @IsTest
    static void testGetCurrentWeatherSuccess() {
        // Mock successful API response
        String mockResponse = '{\n' +
            '  \"coord\": {\"lon\": -0.1257, \"lat\": 51.5085},\n' +
            '  \"weather\": [{\n' +
            '    \"id\": 800,\n' +
            '    \"main\": \"Clear\",\n' +
            '    \"description\": \"clear sky\",\n' +
            '    \"icon\": \"01d\"\n' +
            '  }],\n' +
            '  \"base\": \"stations\",\n' +
            '  \"main\": {\n' +
            '    \"temp\": 22.5,\n' +
            '    \"feels_like\": 23.1,\n' +
            '    \"temp_min\": 20.0,\n' +
            '    \"temp_max\": 25.0,\n' +
            '    \"pressure\": 1013,\n' +
            '    \"humidity\": 65\n' +
            '  },\n' +
            '  \"visibility\": 10000,\n' +
            '  \"wind\": {\n' +
            '    \"speed\": 3.5,\n' +
            '    \"deg\": 180\n' +
            '  },\n' +
            '  \"clouds\": {\"all\": 0},\n' +
            '  \"dt\": 1641024000,\n' +
            '  \"sys\": {\n' +
            '    \"type\": 2,\n' +
            '    \"id\": 2019646,\n' +
            '    \"country\": \"GB\",\n' +
            '    \"sunrise\": 1640999400,\n' +
            '    \"sunset\": 1641027600\n' +
            '  },\n' +
            '  \"timezone\": 0,\n' +
            '  \"id\": 2643743,\n' +
            '  \"name\": \"London\",\n' +
            '  \"cod\": 200\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockWeatherAPICallout(200, mockResponse));
        
        Test.startTest();
        
        WeatherAPIService.WeatherResponse weather = WeatherAPIService.getCurrentWeather('London', 'GB');
        
        Test.stopTest();
        
        // Verify response parsing
        System.assertEquals('London', weather.cityName, 'City name should be parsed correctly');
        System.assertEquals('GB', weather.countryCode, 'Country code should be parsed correctly');
        System.assertEquals(22.5, weather.temperature, 'Temperature should be parsed correctly');
        System.assertEquals(23.1, weather.feelsLike, 'Feels like temperature should be parsed correctly');
        System.assertEquals(65, weather.humidity, 'Humidity should be parsed correctly');
        System.assertEquals(1013, weather.pressure, 'Pressure should be parsed correctly');
        System.assertEquals('Clear', weather.condition, 'Weather condition should be parsed correctly');
        System.assertEquals('clear sky', weather.description, 'Weather description should be parsed correctly');
        System.assertEquals(3.5, weather.windSpeed, 'Wind speed should be parsed correctly');
        System.assertEquals(180, weather.windDirection, 'Wind direction should be parsed correctly');
        System.assertNotEquals(null, weather.timestamp, 'Timestamp should be set');
        
        // Test formatted methods
        System.assertEquals('22.5°C', weather.getFormattedTemperature(), 'Formatted temperature should include unit');
        System.assertEquals('65%', weather.getFormattedHumidity(), 'Formatted humidity should include percentage');
    }
    
    /**
     * @description Test weather forecast retrieval
     */
    @IsTest
    static void testGetWeatherForecast() {
        String mockResponse = '{\n' +
            '  \"cod\": \"200\",\n' +
            '  \"message\": 0,\n' +
            '  \"cnt\": 8,\n' +
            '  \"list\": [\n' +
            '    {\n' +
            '      \"dt\": 1641024000,\n' +
            '      \"main\": {\n' +
            '        \"temp\": 20.5,\n' +
            '        \"feels_like\": 21.0,\n' +
            '        \"humidity\": 70,\n' +
            '        \"pressure\": 1015\n' +
            '      },\n' +
            '      \"weather\": [{\n' +
            '        \"main\": \"Clouds\",\n' +
            '        \"description\": \"few clouds\"\n' +
            '      }],\n' +
            '      \"wind\": {\n' +
            '        \"speed\": 2.5,\n' +
            '        \"deg\": 90\n' +
            '      }\n' +
            '    },\n' +
            '    {\n' +
            '      \"dt\": 1641034800,\n' +
            '      \"main\": {\n' +
            '        \"temp\": 18.0,\n' +
            '        \"feels_like\": 18.5,\n' +
            '        \"humidity\": 75,\n' +
            '        \"pressure\": 1012\n' +
            '      },\n' +
            '      \"weather\": [{\n' +
            '        \"main\": \"Rain\",\n' +
            '        \"description\": \"light rain\"\n' +
            '      }],\n' +
            '      \"wind\": {\n' +
            '        \"speed\": 4.0,\n' +
            '        \"deg\": 120\n' +
            '      }\n' +
            '    }\n' +
            '  ],\n' +
            '  \"city\": {\n' +
            '    \"id\": 2643743,\n' +
            '    \"name\": \"London\",\n' +
            '    \"coord\": {\"lat\": 51.5085, \"lon\": -0.1257},\n' +
            '    \"country\": \"GB\"\n' +
            '  }\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockWeatherAPICallout(200, mockResponse));
        
        Test.startTest();
        
        WeatherAPIService.WeatherForecastResponse forecast = WeatherAPIService.getWeatherForecast('London', 3);
        
        Test.stopTest();
        
        // Verify forecast response
        System.assertEquals('London', forecast.cityName, 'Forecast city name should be correct');
        System.assertEquals('GB', forecast.countryCode, 'Forecast country code should be correct');
        System.assertEquals(2, forecast.forecasts.size(), 'Should have 2 forecast items');
        
        // Verify first forecast item
        WeatherAPIService.WeatherResponse firstForecast = forecast.forecasts[0];
        System.assertEquals(20.5, firstForecast.temperature, 'First forecast temperature should be correct');
        System.assertEquals('Clouds', firstForecast.condition, 'First forecast condition should be correct');
        
        // Test daily forecasts method
        List<WeatherAPIService.WeatherResponse> dailyForecasts = forecast.getDailyForecasts();
        System.assert(dailyForecasts.size() <= forecast.forecasts.size(), 'Daily forecasts should not exceed total forecasts');
    }
    
    /**
     * @description Test bulk weather data retrieval
     */
    @IsTest
    static void testGetBulkWeatherData() {
        String mockResponse = '{\n' +
            '  \"name\": \"TestCity\",\n' +
            '  \"sys\": {\"country\": \"US\"},\n' +
            '  \"main\": {\n' +
            '    \"temp\": 25.0,\n' +
            '    \"feels_like\": 26.0,\n' +
            '    \"humidity\": 60,\n' +
            '    \"pressure\": 1020\n' +
            '  },\n' +
            '  \"weather\": [{\n' +
            '    \"main\": \"Sunny\",\n' +
            '    \"description\": \"sunny day\"\n' +
            '  }],\n' +
            '  \"wind\": {\n' +
            '    \"speed\": 5.0,\n' +
            '    \"deg\": 270\n' +
            '  },\n' +
            '  \"cod\": 200\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockWeatherAPICallout(200, mockResponse));
        
        Test.startTest();
        
        List<String> cities = new List<String>{'New York', 'Los Angeles', 'Chicago'};
        List<WeatherAPIService.WeatherResponse> weatherData = WeatherAPIService.getBulkWeatherData(cities);
        
        Test.stopTest();
        
        // Verify bulk response
        System.assertEquals(3, weatherData.size(), 'Should return weather data for all cities');
        
        for (WeatherAPIService.WeatherResponse weather : weatherData) {
            System.assertEquals('TestCity', weather.cityName, 'Each response should have city name');
            System.assertEquals(25.0, weather.temperature, 'Each response should have temperature');
        }
    }
    
    /**
     * @description Test error handling for invalid city
     */
    @IsTest
    static void testCityNotFound() {
        String errorResponse = '{\n' +
            '  \"cod\": \"404\",\n' +
            '  \"message\": \"city not found\"\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockWeatherAPICallout(404, errorResponse));
        
        Test.startTest();
        
        try {
            WeatherAPIService.getCurrentWeather('InvalidCity', null);
            System.assert(false, 'Should have thrown an exception for invalid city');
        } catch (WeatherAPIService.WeatherAPIException e) {
            System.assert(e.getMessage().contains('City not found'), 'Should throw city not found exception');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test error handling for unauthorized access
     */
    @IsTest
    static void testUnauthorizedAccess() {
        String errorResponse = '{\n' +
            '  \"cod\": 401,\n' +
            '  \"message\": \"Invalid API key\"\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockWeatherAPICallout(401, errorResponse));
        
        Test.startTest();
        
        try {
            WeatherAPIService.getCurrentWeather('London', 'GB');
            System.assert(false, 'Should have thrown an exception for unauthorized access');
        } catch (WeatherAPIService.WeatherAPIException e) {
            System.assert(e.getMessage().contains('Invalid API key'), 'Should throw unauthorized exception');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test error handling for rate limiting
     */
    @IsTest
    static void testRateLimitExceeded() {
        String errorResponse = '{\n' +
            '  \"cod\": 429,\n' +
            '  \"message\": \"Your account is temporary blocked due to exceeding of requests limitation\"\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockWeatherAPICallout(429, errorResponse));
        
        Test.startTest();
        
        try {
            WeatherAPIService.getCurrentWeather('London', 'GB');
            System.assert(false, 'Should have thrown an exception for rate limiting');
        } catch (WeatherAPIService.WeatherAPIException e) {
            System.assert(e.getMessage().contains('rate limit'), 'Should throw rate limit exception');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test error handling for server errors
     */
    @IsTest
    static void testServerError() {
        String errorResponse = '{\n' +
            '  \"cod\": 500,\n' +
            '  \"message\": \"Internal server error\"\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockWeatherAPICallout(500, errorResponse));
        
        Test.startTest();
        
        try {
            WeatherAPIService.getCurrentWeather('London', 'GB');
            System.assert(false, 'Should have thrown an exception for server error');
        } catch (WeatherAPIService.WeatherAPIException e) {
            System.assert(e.getMessage().contains('API Error'), 'Should throw API error exception');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test input validation
     */
    @IsTest
    static void testInputValidation() {
        Test.startTest();
        
        // Test null city name
        try {
            WeatherAPIService.getCurrentWeather(null, 'US');
            System.assert(false, 'Should throw exception for null city name');
        } catch (WeatherAPIService.WeatherAPIException e) {
            System.assert(e.getMessage().contains('City name is required'), 'Should validate city name');
        }
        
        // Test blank city name
        try {
            WeatherAPIService.getCurrentWeather('', 'US');
            System.assert(false, 'Should throw exception for blank city name');
        } catch (WeatherAPIService.WeatherAPIException e) {
            System.assert(e.getMessage().contains('City name is required'), 'Should validate city name');
        }
        
        // Test empty city list for bulk operation
        List<WeatherAPIService.WeatherResponse> result = WeatherAPIService.getBulkWeatherData(new List<String>());
        System.assertEquals(0, result.size(), 'Should return empty list for empty input');
        
        // Test null city list for bulk operation
        List<WeatherAPIService.WeatherResponse> result2 = WeatherAPIService.getBulkWeatherData(null);
        System.assertEquals(0, result2.size(), 'Should return empty list for null input');
        
        Test.stopTest();
    }
    
    /**
     * @description Test JSON parsing error handling
     */
    @IsTest
    static void testInvalidJSONResponse() {
        String invalidResponse = 'This is not valid JSON';\n        
        Test.setMock(HttpCalloutMock.class, new MockWeatherAPICallout(200, invalidResponse));
        
        Test.startTest();
        
        try {
            WeatherAPIService.getCurrentWeather('London', 'GB');
            System.assert(false, 'Should throw exception for invalid JSON');
        } catch (WeatherAPIService.WeatherAPIException e) {
            System.assert(e.getMessage().contains('Failed to parse'), 'Should throw parsing exception');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test network timeout simulation
     */
    @IsTest
    static void testNetworkTimeout() {
        // Mock a callout exception to simulate network issues
        Test.setMock(HttpCalloutMock.class, new CalloutExceptionMock());
        
        Test.startTest();
        
        try {
            WeatherAPIService.getCurrentWeather('London', 'GB');
            System.assert(false, 'Should throw exception for network timeout');
        } catch (WeatherAPIService.WeatherAPIException e) {
            System.assert(e.getMessage().contains('Network error'), 'Should throw network error exception');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Mock class to simulate CalloutException
     */
    private class CalloutExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            throw new CalloutException('Connection timeout');
        }
    }
    
    /**
     * @description Test forecast with invalid days parameter
     */
    @IsTest
    static void testForecastInvalidDays() {
        String mockResponse = '{\n' +
            '  \"cod\": \"200\",\n' +
            '  \"list\": [],\n' +
            '  \"city\": {\"name\": \"London\", \"country\": \"GB\"}\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockWeatherAPICallout(200, mockResponse));
        
        Test.startTest();
        
        // Test with null days - should default to 3
        WeatherAPIService.WeatherForecastResponse forecast1 = WeatherAPIService.getWeatherForecast('London', null);
        System.assertNotEquals(null, forecast1, 'Should handle null days parameter');
        
        // Test with invalid days (too high) - should default to 3
        WeatherAPIService.WeatherForecastResponse forecast2 = WeatherAPIService.getWeatherForecast('London', 10);
        System.assertNotEquals(null, forecast2, 'Should handle invalid days parameter');
        
        // Test with invalid days (too low) - should default to 3
        WeatherAPIService.WeatherForecastResponse forecast3 = WeatherAPIService.getWeatherForecast('London', 0);
        System.assertNotEquals(null, forecast3, 'Should handle invalid days parameter');
        
        Test.stopTest();
    }
}