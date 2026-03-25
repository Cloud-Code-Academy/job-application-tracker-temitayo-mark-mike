/**
 * @description Service class for integrating with OpenWeatherMap API
 * Demonstrates enterprise API integration patterns and best practices
 * @author Learning Journey
 * @date 2025-01-08
 */
public with sharing class WeatherAPIService {
    
    // API Configuration - In production, use Named Credentials or Custom Settings
    private static final String BASE_URL = 'https://api.openweathermap.org/data/2.5';
    private static final String API_KEY = 'demo_key'; // Use Named Credentials in production
    private static final Integer TIMEOUT = 10000; // 10 seconds
    private static final Integer RETRY_ATTEMPTS = 3;
    
    /**
     * @description Gets current weather data for a city
     * @param cityName Name of the city
     * @param countryCode Optional country code (e.g., 'US', 'UK')
     * @return WeatherResponse with current weather data
     */
    public static WeatherResponse getCurrentWeather(String cityName, String countryCode) {
        if (String.isBlank(cityName)) {
            throw new WeatherAPIException('City name is required');
        }
        
        try {
            // Build the API request
            HttpRequest request = buildWeatherRequest(cityName, countryCode);
            
            // Execute with retry logic
            HttpResponse response = executeWithRetry(request);
            
            // Parse and return the response
            return parseWeatherResponse(response);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching weather data: ' + e.getMessage());
            throw new WeatherAPIException('Failed to fetch weather data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets weather forecast for multiple days
     * @param cityName Name of the city
     * @param days Number of days for forecast (1-5)
     * @return WeatherForecastResponse with forecast data
     */
    public static WeatherForecastResponse getWeatherForecast(String cityName, Integer days) {
        if (String.isBlank(cityName)) {
            throw new WeatherAPIException('City name is required');
        }
        
        if (days == null || days < 1 || days > 5) {
            days = 3; // Default to 3 days
        }
        
        try {
            HttpRequest request = buildForecastRequest(cityName, days);
            HttpResponse response = executeWithRetry(request);
            return parseForecastResponse(response);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching weather forecast: ' + e.getMessage());
            throw new WeatherAPIException('Failed to fetch weather forecast: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets weather data for multiple cities in bulk
     * @param cityNames List of city names
     * @return List of WeatherResponse objects
     */
    public static List<WeatherResponse> getBulkWeatherData(List<String> cityNames) {
        List<WeatherResponse> responses = new List<WeatherResponse>();
        
        if (cityNames == null || cityNames.isEmpty()) {
            return responses;
        }
        
        // Process cities in batches to respect API limits
        for (String cityName : cityNames) {
            try {
                WeatherResponse weather = getCurrentWeather(cityName, null);
                responses.add(weather);
                
                // Add small delay between requests to be respectful to API
                // In production, consider using Platform Events for async processing
                
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Failed to get weather for ' + cityName + ': ' + e.getMessage());
                // Continue processing other cities rather than failing completely
            }
        }
        
        return responses;
    }
    
    /**
     * @description Builds HTTP request for current weather
     * @param cityName City name
     * @param countryCode Country code
     * @return Configured HttpRequest
     */
    private static HttpRequest buildWeatherRequest(String cityName, String countryCode) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(BASE_URL + '/weather');
        request.setMethod('GET');
        request.setTimeout(TIMEOUT);
        
        // Set headers
        request.setHeader('Accept', 'application/json');
        request.setHeader('User-Agent', 'Salesforce-WeatherService/1.0');
        
        // Build query parameters
        Map<String, String> params = new Map<String, String>{
            'q' => buildCityQuery(cityName, countryCode),
            'appid' => API_KEY,
            'units' => 'metric', // Celsius
            'lang' => 'en'
        };
        
        String queryParams = buildQueryParams(params);
        request.setEndpoint(request.getEndpoint() + '?' + queryParams);
        
        return request;
    }
    
    /**
     * @description Builds HTTP request for weather forecast
     * @param cityName City name
     * @param days Number of forecast days
     * @return Configured HttpRequest
     */
    private static HttpRequest buildForecastRequest(String cityName, Integer days) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(BASE_URL + '/forecast');
        request.setMethod('GET');
        request.setTimeout(TIMEOUT);
        
        // Set headers
        request.setHeader('Accept', 'application/json');
        request.setHeader('User-Agent', 'Salesforce-WeatherService/1.0');
        
        // Build query parameters
        Map<String, String> params = new Map<String, String>{
            'q' => EncodingUtil.urlEncode(cityName, 'UTF-8'),
            'appid' => API_KEY,
            'units' => 'metric',
            'cnt' => String.valueOf(days * 8) // 8 forecasts per day (3-hour intervals)
        };
        
        String queryParams = buildQueryParams(params);
        request.setEndpoint(request.getEndpoint() + '?' + queryParams);
        
        return request;
    }
    
    /**
     * @description Executes HTTP request with retry logic and exponential backoff
     * @param request HttpRequest to execute
     * @return HttpResponse
     */
    private static HttpResponse executeWithRetry(HttpRequest request) {
        Http http = new Http();
        HttpResponse response;
        Integer attempts = 0;
        Integer backoffMs = 1000; // Start with 1 second
        
        while (attempts < RETRY_ATTEMPTS) {
            attempts++;
            
            try {
                response = http.send(request);
                
                // Success case
                if (response.getStatusCode() == 200) {
                    return response;
                }
                
                // Handle different HTTP status codes
                if (response.getStatusCode() == 401) {
                    throw new WeatherAPIException('Invalid API key or unauthorized access');
                } else if (response.getStatusCode() == 404) {
                    throw new WeatherAPIException('City not found');
                } else if (response.getStatusCode() == 429) {
                    // Rate limit exceeded - wait longer before retry
                    if (attempts < RETRY_ATTEMPTS) {
                        System.debug('Rate limit exceeded, waiting before retry...');
                        // In a real implementation, you might use Platform Events for delayed retry
                        continue;
                    }
                    throw new WeatherAPIException('API rate limit exceeded');
                } else if (response.getStatusCode() >= 500 && attempts < RETRY_ATTEMPTS) {
                    // Server error - retry with exponential backoff
                    System.debug('Server error (HTTP ' + response.getStatusCode() + '), retrying... Attempt ' + attempts);
                    // Exponential backoff: wait longer between retries
                    backoffMs *= 2;
                    continue;
                } else {
                    throw new WeatherAPIException('API Error: HTTP ' + response.getStatusCode() + ' - ' + response.getBody());
                }
                
            } catch (CalloutException e) {
                if (attempts < RETRY_ATTEMPTS) {
                    System.debug('Network error, retrying... Attempt ' + attempts + ': ' + e.getMessage());
                    continue;
                } else {
                    throw new WeatherAPIException('Network error after ' + RETRY_ATTEMPTS + ' attempts: ' + e.getMessage());
                }
            }
        }
        
        throw new WeatherAPIException('Failed after ' + RETRY_ATTEMPTS + ' attempts');
    }
    
    /**
     * @description Parses weather API response
     * @param response HttpResponse from API
     * @return WeatherResponse object
     */
    private static WeatherResponse parseWeatherResponse(HttpResponse response) {
        try {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            // Check for API error in response
            if (responseData.containsKey('cod') && responseData.get('cod') != 200) {
                String errorMessage = (String) responseData.get('message');
                throw new WeatherAPIException('API Error: ' + errorMessage);
            }
            
            // Extract main weather data
            Map<String, Object> main = (Map<String, Object>) responseData.get('main');
            List<Object> weatherList = (List<Object>) responseData.get('weather');
            Map<String, Object> weather = (Map<String, Object>) weatherList[0];
            Map<String, Object> wind = (Map<String, Object>) responseData.get('wind');
            Map<String, Object> sys = (Map<String, Object>) responseData.get('sys');
            
            return new WeatherResponse(
                (String) responseData.get('name'), // city name
                (String) sys?.get('country'), // country code
                (Decimal) main.get('temp'), // temperature
                (Decimal) main.get('feels_like'), // feels like temperature
                (Decimal) main.get('humidity'), // humidity percentage
                (Decimal) main.get('pressure'), // atmospheric pressure
                (String) weather.get('main'), // weather condition
                (String) weather.get('description'), // weather description
                (Decimal) wind?.get('speed'), // wind speed
                (Integer) wind?.get('deg'), // wind direction
                DateTime.now() // timestamp
            );
            
        } catch (Exception e) {
            throw new WeatherAPIException('Failed to parse weather response: ' + e.getMessage());
        }
    }
    
    /**
     * @description Parses weather forecast API response
     * @param response HttpResponse from API
     * @return WeatherForecastResponse object
     */
    private static WeatherForecastResponse parseForecastResponse(HttpResponse response) {
        try {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            List<Object> forecastList = (List<Object>) responseData.get('list');
            List<WeatherResponse> forecasts = new List<WeatherResponse>();
            
            Map<String, Object> city = (Map<String, Object>) responseData.get('city');
            String cityName = (String) city.get('name');
            String countryCode = (String) city.get('country');
            
            for (Object forecastObj : forecastList) {
                Map<String, Object> forecast = (Map<String, Object>) forecastObj;
                Map<String, Object> main = (Map<String, Object>) forecast.get('main');
                List<Object> weatherList = (List<Object>) forecast.get('weather');
                Map<String, Object> weather = (Map<String, Object>) weatherList[0];
                Map<String, Object> wind = (Map<String, Object>) forecast.get('wind');
                
                // Convert Unix timestamp to DateTime
                Long unixTimestamp = (Long) forecast.get('dt');
                DateTime forecastTime = DateTime.newInstance(unixTimestamp * 1000);
                
                WeatherResponse forecastItem = new WeatherResponse(
                    cityName,
                    countryCode,
                    (Decimal) main.get('temp'),
                    (Decimal) main.get('feels_like'),
                    (Decimal) main.get('humidity'),
                    (Decimal) main.get('pressure'),
                    (String) weather.get('main'),
                    (String) weather.get('description'),
                    (Decimal) wind?.get('speed'),
                    (Integer) wind?.get('deg'),
                    forecastTime
                );
                
                forecasts.add(forecastItem);
            }
            
            return new WeatherForecastResponse(cityName, countryCode, forecasts);
            
        } catch (Exception e) {
            throw new WeatherAPIException('Failed to parse forecast response: ' + e.getMessage());
        }
    }
    
    /**
     * @description Builds city query string with optional country code
     * @param cityName City name
     * @param countryCode Country code
     * @return Formatted city query
     */
    private static String buildCityQuery(String cityName, String countryCode) {
        String query = EncodingUtil.urlEncode(cityName, 'UTF-8');
        if (String.isNotBlank(countryCode)) {
            query += ',' + EncodingUtil.urlEncode(countryCode, 'UTF-8');
        }
        return query;
    }
    
    /**
     * @description Builds query parameter string from map
     * @param params Map of parameter key-value pairs
     * @return URL-encoded query string
     */
    private static String buildQueryParams(Map<String, String> params) {
        List<String> paramList = new List<String>();
        
        for (String key : params.keySet()) {
            String value = params.get(key);
            if (String.isNotBlank(value)) {
                paramList.add(key + '=' + value);
            }
        }
        
        return String.join(paramList, '&');
    }
    
    /**
     * @description Custom exception for weather API errors
     */
    public class WeatherAPIException extends Exception {}
    
    /**
     * @description Response wrapper for weather data
     */
    public class WeatherResponse {
        public String cityName;
        public String countryCode;
        public Decimal temperature;
        public Decimal feelsLike;
        public Decimal humidity;
        public Decimal pressure;
        public String condition;
        public String description;
        public Decimal windSpeed;
        public Integer windDirection;
        public DateTime timestamp;
        
        public WeatherResponse(String city, String country, Decimal temp, Decimal feels, 
                              Decimal humid, Decimal press, String cond, String desc,
                              Decimal windSpd, Integer windDir, DateTime time) {
            this.cityName = city;
            this.countryCode = country;
            this.temperature = temp;
            this.feelsLike = feels;
            this.humidity = humid;
            this.pressure = press;
            this.condition = cond;
            this.description = desc;
            this.windSpeed = windSpd;
            this.windDirection = windDir;
            this.timestamp = time;
        }
        
        /**
         * @description Gets formatted temperature string
         * @return Temperature with unit (e.g., "22.5°C")
         */
        public String getFormattedTemperature() {
            return this.temperature != null ? this.temperature.setScale(1) + '°C' : 'N/A';
        }
        
        /**
         * @description Gets formatted humidity string
         * @return Humidity with percentage (e.g., "65%")
         */
        public String getFormattedHumidity() {
            return this.humidity != null ? this.humidity.intValue() + '%' : 'N/A';
        }
    }
    
    /**
     * @description Response wrapper for weather forecast data
     */
    public class WeatherForecastResponse {
        public String cityName;
        public String countryCode;
        public List<WeatherResponse> forecasts;
        
        public WeatherForecastResponse(String city, String country, List<WeatherResponse> forecastList) {
            this.cityName = city;
            this.countryCode = country;
            this.forecasts = forecastList != null ? forecastList : new List<WeatherResponse>();
        }
        
        /**
         * @description Gets daily forecast summaries (one per day)
         * @return List of daily weather summaries
         */
        public List<WeatherResponse> getDailyForecasts() {
            List<WeatherResponse> dailyForecasts = new List<WeatherResponse>();
            Set<Date> processedDates = new Set<Date>();
            
            for (WeatherResponse forecast : this.forecasts) {
                Date forecastDate = forecast.timestamp.date();
                if (!processedDates.contains(forecastDate)) {
                    dailyForecasts.add(forecast);
                    processedDates.add(forecastDate);
                }
            }
            
            return dailyForecasts;
        }
    }
}