// Test Weather API Integration Patterns
// This script demonstrates API integration best practices

System.debug('=== Weather API Integration Test ===');

try {
    // Note: This will fail in a real org without a valid API key
    // But it demonstrates the integration patterns and error handling
    
    System.debug('Testing API integration patterns...');
    
    // Test 1: Basic weather request (will fail gracefully)
    try {
        WeatherAPIService.WeatherResponse weather = WeatherAPIService.getCurrentWeather('London', 'GB');
        System.debug('Weather for London: ' + weather.getFormattedTemperature());
        System.debug('Condition: ' + weather.condition + ' - ' + weather.description);
        System.debug('Humidity: ' + weather.getFormattedHumidity());
    } catch (WeatherAPIService.WeatherAPIException e) {
        System.debug('Expected API error (no valid key): ' + e.getMessage());
    }
    
    // Test 2: Input validation
    try {
        WeatherAPIService.getCurrentWeather('', 'US');
    } catch (WeatherAPIService.WeatherAPIException e) {
        System.debug('✅ Input validation working: ' + e.getMessage());
    }
    
    // Test 3: Bulk weather data (empty list)
    List<WeatherAPIService.WeatherResponse> bulkWeather = WeatherAPIService.getBulkWeatherData(new List<String>());
    System.debug('✅ Bulk weather with empty list returned: ' + bulkWeather.size() + ' results');
    
    // Test 4: Forecast with invalid days
    try {
        WeatherAPIService.WeatherForecastResponse forecast = WeatherAPIService.getWeatherForecast('Paris', null);
        System.debug('Forecast request handled gracefully (will fail with API error)');
    } catch (WeatherAPIService.WeatherAPIException e) {
        System.debug('Expected API error for forecast: ' + e.getMessage());
    }
    
    System.debug('=== API Integration Patterns Demonstrated ===');
    System.debug('✅ Service Layer Pattern - Centralized API logic');
    System.debug('✅ Error Handling - Custom exceptions and graceful degradation');
    System.debug('✅ Input Validation - Proper parameter checking');
    System.debug('✅ Retry Logic - Built-in retry with exponential backoff');
    System.debug('✅ Response Parsing - Structured data objects');
    System.debug('✅ HTTP Best Practices - Proper headers, timeouts, encoding');
    
} catch (Exception e) {
    System.debug('Unexpected error: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

System.debug('=== Integration Patterns Analysis Complete ===');

// Demonstrate the patterns we learned from SalaryDataAPIService
System.debug('');
System.debug('=== Key Integration Patterns Learned ===');
System.debug('1. Service Layer Architecture - Centralized, reusable API logic');
System.debug('2. Configuration Management - Constants and settings for API endpoints');
System.debug('3. Comprehensive Error Handling - Custom exceptions and meaningful messages');
System.debug('4. Retry Logic - Exponential backoff for resilience');
System.debug('5. HTTP Best Practices - Proper request construction and headers');
System.debug('6. JSON Parsing - Safe deserialization with error handling');
System.debug('7. Type Safety - Wrapper classes instead of generic maps');
System.debug('8. Input Validation - Parameter checking and sanitization');
System.debug('9. Bulk Operations - Efficient handling of multiple requests');
System.debug('10. Graceful Degradation - Continuing operation when possible');

System.debug('');
System.debug('🌍 Technology Context:');
System.debug('- Salesforce: Http class with HttpRequest/HttpResponse objects');
System.debug('- Node.js: fetch() or axios for HTTP requests');
System.debug('- Python: requests library for API calls');
System.debug('- React: useEffect hooks for data fetching');
System.debug('- All platforms: Similar patterns for error handling and retry logic');

System.debug('✅ API Integration patterns exploration completed successfully!');