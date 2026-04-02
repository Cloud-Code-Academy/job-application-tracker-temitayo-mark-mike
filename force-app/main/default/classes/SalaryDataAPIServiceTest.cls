/**
 * @description Test class for SalaryDataAPIService
 * @author Test Coverage
 * @date 2024
 */
@IsTest
private inherited sharing class SalaryDataAPIServiceTest {

    /**
     * @description Mock HTTP callout class that returns appropriate JSON responses
     *              based on the endpoint being called.
     */
    private class SalaryDataAPIMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);

            String endpoint = request.getEndpoint();

            if (endpoint.contains('/salary-data/bulk')) {
                // Bulk salary data response
                response.setBody(
                    '{"results":[{"salary_data":{"min_salary":80000,"max_salary":150000,' +
                    '"median_salary":110000,"percentile_75":130000,"currency":"USD"},' +
                    '"data_source":"test","last_updated":"2024-01-15"}]}'
                );
            } else if (endpoint.contains('/salary-data')) {
                // Single salary data response
                response.setBody(
                    '{"salary_data":{"min_salary":80000,"max_salary":150000,' +
                    '"median_salary":110000,"percentile_75":130000,"currency":"USD"},' +
                    '"data_source":"test","last_updated":"2024-01-15"}'
                );
            } else if (endpoint.contains('/trends')) {
                // Salary trends response
                response.setBody(
                    '{"trend_data":{"industry":"Technology","trend_direction":"up",' +
                    '"growth_percentage":5.2,"monthly_data":[]}}'
                );
            } else {
                // Default response
                response.setBody('{"status":"ok"}');
            }

            return response;
        }
    }

    /**
     * @description Test getSalaryData with a valid position title using HTTP mock
     */
    @IsTest
    static void testGetSalaryDataSuccess() {
        Test.setMock(HttpCalloutMock.class, new SalaryDataAPIMock());

        Test.startTest();
        SalaryDataAPIService.SalaryDataResponse result =
            SalaryDataAPIService.getSalaryData('Software Engineer', 'San Francisco, CA', 'senior');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Response should not be null');
        System.assertEquals(80000, result.minSalary, 'Min salary should match');
        System.assertEquals(150000, result.maxSalary, 'Max salary should match');
        System.assertEquals(110000, result.medianSalary, 'Median salary should match');
        System.assertEquals(130000, result.percentile75, 'Percentile 75 should match');
        System.assertEquals('USD', result.currencyCode, 'Currency should match');
        System.assertEquals('test', result.dataSource, 'Data source should match');
        System.assertNotEquals(null, result.lastUpdated, 'Last updated should not be null');
    }

    /**
     * @description Test getSalaryData throws SalaryDataException for blank position title
     */
    @IsTest
    static void testGetSalaryDataBlankPositionTitle() {
        Test.startTest();
        try {
            SalaryDataAPIService.getSalaryData('', 'New York, NY', 'mid');
            System.assert(false, 'Should have thrown SalaryDataException for blank position title');
        } catch (SalaryDataAPIService.SalaryDataException e) {
            System.assert(
                e.getMessage().contains('Position title is required'),
                'Exception message should indicate position title is required'
            );
        }
        Test.stopTest();
    }

    /**
     * @description Test getSalaryData throws SalaryDataException for null position title
     */
    @IsTest
    static void testGetSalaryDataNullPositionTitle() {
        Test.startTest();
        try {
            SalaryDataAPIService.getSalaryData(null, 'New York, NY', 'mid');
            System.assert(false, 'Should have thrown SalaryDataException for null position title');
        } catch (SalaryDataAPIService.SalaryDataException e) {
            System.assert(
                e.getMessage().contains('Position title is required'),
                'Exception message should indicate position title is required'
            );
        }
        Test.stopTest();
    }

    /**
     * @description Test getBulkSalaryData with mock callout
     */
    @IsTest
    static void testGetBulkSalaryData() {
        Test.setMock(HttpCalloutMock.class, new SalaryDataAPIMock());

        List<SalaryDataAPIService.SalaryDataRequest> requests = new List<SalaryDataAPIService.SalaryDataRequest>();
        requests.add(new SalaryDataAPIService.SalaryDataRequest('Software Engineer', 'San Francisco', 'senior'));
        requests.add(new SalaryDataAPIService.SalaryDataRequest('Product Manager', 'New York', 'mid'));

        Test.startTest();
        List<SalaryDataAPIService.SalaryDataResponse> results =
            SalaryDataAPIService.getBulkSalaryData(requests);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Should return at least one result');
        System.assertEquals(80000, results[0].minSalary, 'Min salary should match');
    }

    /**
     * @description Test getBulkSalaryData with empty list returns empty results
     */
    @IsTest
    static void testGetBulkSalaryDataEmptyList() {
        Test.startTest();
        List<SalaryDataAPIService.SalaryDataResponse> results =
            SalaryDataAPIService.getBulkSalaryData(new List<SalaryDataAPIService.SalaryDataRequest>());
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Results should be empty for empty request list');
    }

    /**
     * @description Test getBulkSalaryData with null list returns empty results
     */
    @IsTest
    static void testGetBulkSalaryDataNullList() {
        Test.startTest();
        List<SalaryDataAPIService.SalaryDataResponse> results =
            SalaryDataAPIService.getBulkSalaryData(null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Results should be empty for null request list');
    }

    /**
     * @description Test getSalaryTrends with mock callout
     */
    @IsTest
    static void testGetSalaryTrends() {
        Test.setMock(HttpCalloutMock.class, new SalaryDataAPIMock());

        Test.startTest();
        SalaryDataAPIService.SalaryTrendResponse result =
            SalaryDataAPIService.getSalaryTrends('Technology', '1y');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Trend response should not be null');
        System.assertEquals('Technology', result.industry, 'Industry should match');
        System.assertEquals('up', result.trendDirection, 'Trend direction should match');
        System.assertEquals(5.2, result.growthPercentage, 'Growth percentage should match');
        System.assertNotEquals(null, result.monthlyData, 'Monthly data should not be null');
    }

    /**
     * @description Test SalaryDataRequest wrapper class constructor
     */
    @IsTest
    static void testSalaryDataRequestConstructor() {
        Test.startTest();
        SalaryDataAPIService.SalaryDataRequest request =
            new SalaryDataAPIService.SalaryDataRequest('Data Scientist', 'Austin, TX', 'entry');
        Test.stopTest();

        System.assertEquals('Data Scientist', request.positionTitle, 'Position title should match');
        System.assertEquals('Austin, TX', request.location, 'Location should match');
        System.assertEquals('entry', request.experienceLevel, 'Experience level should match');
    }

    /**
     * @description Test SalaryDataResponse wrapper class constructor
     */
    @IsTest
    static void testSalaryDataResponseConstructor() {
        Test.startTest();
        SalaryDataAPIService.SalaryDataResponse response =
            new SalaryDataAPIService.SalaryDataResponse(
                70000, 140000, 100000, 120000, 'USD', 'manual', Date.today()
            );
        Test.stopTest();

        System.assertEquals(70000, response.minSalary, 'Min salary should match');
        System.assertEquals(140000, response.maxSalary, 'Max salary should match');
        System.assertEquals(100000, response.medianSalary, 'Median salary should match');
        System.assertEquals(120000, response.percentile75, 'Percentile 75 should match');
        System.assertEquals('USD', response.currencyCode, 'Currency should match');
        System.assertEquals('manual', response.dataSource, 'Data source should match');
        System.assertEquals(Date.today(), response.lastUpdated, 'Last updated should match');
    }

    /**
     * @description Test SalaryTrendResponse wrapper class constructor
     */
    @IsTest
    static void testSalaryTrendResponseConstructor() {
        Test.startTest();
        List<Object> monthlyData = new List<Object>();
        SalaryDataAPIService.SalaryTrendResponse response =
            new SalaryDataAPIService.SalaryTrendResponse('Finance', 'down', -2.1, monthlyData);
        Test.stopTest();

        System.assertEquals('Finance', response.industry, 'Industry should match');
        System.assertEquals('down', response.trendDirection, 'Trend direction should match');
        System.assertEquals(-2.1, response.growthPercentage, 'Growth percentage should match');
        System.assertNotEquals(null, response.monthlyData, 'Monthly data should not be null');
    }
}
