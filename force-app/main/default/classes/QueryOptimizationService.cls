/**
 * @description Advanced query optimization service demonstrating efficient SOQL patterns
 * Implements selective queries, indexed field usage, and query plan optimization
 * @author Learning Journey - Task 8.2
 * @date 2025-01-08
 */
public with sharing class QueryOptimizationService {
    
    /**
     * @description Demonstrates efficient vs inefficient query patterns
     * @param recordLimit Number of records to query
     * @return Map<String, Object> Performance comparison results
     */
    public static Map<String, Object> compareQueryPatterns(Integer recordLimit) {
        Map<String, Object> results = new Map<String, Object>();
        
        // Pattern 1: Inefficient - Select all fields
        Long startTime = System.currentTimeMillis();
        Integer initialQueries = Limits.getQueries();
        Integer initialCpuTime = Limits.getCpuTime();
        
        List<Job_Application__c> inefficientQuery = [
            SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, 
                   Salary__c, Location__c, Application_Date__c, Notes__c,
                   Federal_Tax__c, Social_Security_Tax__c, Medicare_Tax__c,
                   Take_Home_Pay_Yearly__c, Take_Home_Pay_Monthly__c,
                   Primary_Contact__c, CreatedDate, LastModifiedDate
            FROM Job_Application__c 
            LIMIT :recordLimit
        ];
        
        Long inefficientTime = System.currentTimeMillis() - startTime;
        Integer inefficientCpuTime = Limits.getCpuTime() - initialCpuTime;
        
        // Pattern 2: Efficient - Select only needed fields
        startTime = System.currentTimeMillis();
        Integer efficientBaselineCpu = Limits.getCpuTime();
        
        List<Job_Application__c> efficientQuery = [
            SELECT Id, Company_Name__c, Status__c, Salary__c
            FROM Job_Application__c 
            LIMIT :recordLimit
        ];
        
        Long efficientTime = System.currentTimeMillis() - startTime;
        Integer efficientCpuTime = Limits.getCpuTime() - efficientBaselineCpu;
        
        // Pattern 3: Indexed field query
        startTime = System.currentTimeMillis();
        Integer indexedBaselineCpu = Limits.getCpuTime();
        
        List<Job_Application__c> indexedQuery = [
            SELECT Id, Company_Name__c, Status__c, Salary__c
            FROM Job_Application__c 
            WHERE Status__c = 'Applied'
            LIMIT :recordLimit
        ];
        
        Long indexedTime = System.currentTimeMillis() - startTime;
        Integer indexedCpuTime = Limits.getCpuTime() - indexedBaselineCpu;
        
        // Compile results
        results.put('inefficientQuery', new Map<String, Object>{
            'executionTime' => inefficientTime,
            'cpuTime' => inefficientCpuTime,
            'recordCount' => inefficientQuery.size(),
            'fieldsSelected' => 17
        });
        
        results.put('efficientQuery', new Map<String, Object>{
            'executionTime' => efficientTime,
            'cpuTime' => efficientCpuTime,
            'recordCount' => efficientQuery.size(),
            'fieldsSelected' => 4
        });
        
        results.put('indexedQuery', new Map<String, Object>{
            'executionTime' => indexedTime,
            'cpuTime' => indexedCpuTime,
            'recordCount' => indexedQuery.size(),
            'fieldsSelected' => 4,
            'usesIndex' => true
        });
        
        // Calculate optimization gains
        results.put('optimizationGains', new Map<String, Object>{
            'timeImprovement' => inefficientTime > 0 ? 
                Math.round(((inefficientTime - efficientTime) / inefficientTime) * 100) : 0,
            'cpuImprovement' => inefficientCpuTime > 0 ? 
                Math.round(((inefficientCpuTime - efficientCpuTime) / inefficientCpuTime) * 100) : 0,
            'indexedImprovement' => efficientTime > 0 ? 
                Math.round(((efficientTime - indexedTime) / efficientTime) * 100) : 0
        });
        
        return results;
    }
    
    /**
     * @description Demonstrates efficient bulk data retrieval patterns
     * @param companyNames List of company names to query
     * @return Map<String, List<Job_Application__c>> Applications grouped by company
     */
    public static Map<String, List<Job_Application__c>> getBulkApplicationData(List<String> companyNames) {
        Map<String, List<Job_Application__c>> results = new Map<String, List<Job_Application__c>>();
        
        if (companyNames == null || companyNames.isEmpty()) {
            return results;
        }
        
        // Efficient bulk query instead of multiple individual queries
        List<Job_Application__c> applications = [
            SELECT Id, Company_Name__c, Position_Title__c, Status__c, 
                   Salary__c, Application_Date__c
            FROM Job_Application__c 
            WHERE Company_Name__c IN :companyNames
            ORDER BY Company_Name__c, Application_Date__c DESC
        ];
        
        // Group results by company
        for (Job_Application__c app : applications) {
            if (!results.containsKey(app.Company_Name__c)) {
                results.put(app.Company_Name__c, new List<Job_Application__c>());
            }
            results.get(app.Company_Name__c).add(app);
        }
        
        return results;
    }
    
    /**
     * @description Demonstrates efficient aggregation queries
     * @param dateRange Number of days to look back
     * @return Map<String, Object> Aggregated statistics
     */
    public static Map<String, Object> getAggregatedStatistics(Integer dateRange) {
        Date startDate = Date.today().addDays(-dateRange);
        
        // Efficient aggregation query
        List<AggregateResult> statusStats = [
            SELECT Status__c, COUNT(Id) recordCount, AVG(Salary__c) avgSalary, 
                   MIN(Salary__c) minSalary, MAX(Salary__c) maxSalary
            FROM Job_Application__c 
            WHERE Application_Date__c >= :startDate
            AND Salary__c != null
            GROUP BY Status__c
            ORDER BY COUNT(Id) DESC
        ];
        
        Map<String, Object> results = new Map<String, Object>();
        List<Map<String, Object>> statusData = new List<Map<String, Object>>();
        
        Integer totalApplications = 0;
        Decimal totalSalary = 0;
        
        for (AggregateResult result : statusStats) {
            Integer count = (Integer) result.get('recordCount');
            Decimal avgSalary = (Decimal) result.get('avgSalary');
            
            totalApplications += count;
            totalSalary += (avgSalary * count);
            
            statusData.add(new Map<String, Object>{
                'status' => result.get('Status__c'),
                'count' => count,
                'averageSalary' => avgSalary,
                'minSalary' => result.get('minSalary'),
                'maxSalary' => result.get('maxSalary')
            });
        }
        
        results.put('statusBreakdown', statusData);
        results.put('totalApplications', totalApplications);
        results.put('overallAverageSalary', totalApplications > 0 ? totalSalary / totalApplications : 0);
        results.put('dateRange', dateRange);
        
        return results;
    }
    
    /**
     * @description Demonstrates efficient relationship queries
     * @param applicationIds List of Job Application IDs
     * @return Map<Id, List<Task>> Tasks grouped by Job Application
     */
    public static Map<Id, List<Task>> getRelatedTasks(List<Id> applicationIds) {
        Map<Id, List<Task>> results = new Map<Id, List<Task>>();
        
        if (applicationIds == null || applicationIds.isEmpty()) {
            return results;
        }
        
        // Efficient relationship query
        List<Task> tasks = [
            SELECT Id, Subject, Status, Priority, ActivityDate, WhatId
            FROM Task 
            WHERE WhatId IN :applicationIds
            AND WhatId != null
            ORDER BY WhatId, ActivityDate ASC
        ];
        
        // Group tasks by Job Application
        for (Task task : tasks) {
            if (!results.containsKey(task.WhatId)) {
                results.put(task.WhatId, new List<Task>());
            }
            results.get(task.WhatId).add(task);
        }
        
        return results;
    }
    
    /**
     * @description Demonstrates query optimization with dynamic SOQL
     * @param filters Map of field names to filter values
     * @param sortField Field to sort by
     * @param sortOrder ASC or DESC
     * @param recordLimit Maximum number of records to return
     * @return List<Job_Application__c> Filtered and sorted results
     */
    public static List<Job_Application__c> getDynamicFilteredApplications(
        Map<String, Object> filters, 
        String sortField, 
        String sortOrder, 
        Integer recordLimit
    ) {
        // Build selective field list
        List<String> fields = new List<String>{
            'Id', 'Company_Name__c', 'Position_Title__c', 'Status__c', 
            'Salary__c', 'Application_Date__c'
        };
        
        // Add sort field if not already included
        if (String.isNotBlank(sortField) && !fields.contains(sortField)) {
            fields.add(sortField);
        }
        
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM Job_Application__c';
        
        // Build WHERE clause dynamically
        List<String> whereConditions = new List<String>();
        Map<String, Object> bindVariables = new Map<String, Object>();
        
        if (filters != null && !filters.isEmpty()) {
            for (String fieldName : filters.keySet()) {
                Object value = filters.get(fieldName);
                if (value != null) {
                    String bindVar = 'bind' + whereConditions.size();
                    whereConditions.add(fieldName + ' = :' + bindVar);
                    bindVariables.put(bindVar, value);
                }
            }
        }
        
        if (!whereConditions.isEmpty()) {
            query += ' WHERE ' + String.join(whereConditions, ' AND ');
        }
        
        // Add sorting
        if (String.isNotBlank(sortField)) {
            query += ' ORDER BY ' + sortField;
            if (String.isNotBlank(sortOrder) && sortOrder.toUpperCase() == 'DESC') {
                query += ' DESC';
            }
        }
        
        // Add limit
        if (recordLimit != null && recordLimit > 0) {
            query += ' LIMIT ' + recordLimit;
        }
        
        System.debug('QueryOptimizationService: Dynamic query - ' + query);
        System.debug('QueryOptimizationService: Bind variables - ' + bindVariables);
        
        return Database.queryWithBinds(query, bindVariables, AccessLevel.USER_MODE);
    }
    
    /**
     * @description Demonstrates efficient pagination patterns
     * @param pageSize Number of records per page
     * @param pageNumber Page number (1-based)
     * @param sortField Field to sort by
     * @return PaginationResult Paginated results with metadata
     */
    public static PaginationResult getPaginatedApplications(Integer pageSize, Integer pageNumber, String sortField) {
        // Calculate offset
        Integer offset = (pageNumber - 1) * pageSize;
        
        // Get total count efficiently
        Integer totalRecords = [SELECT COUNT() FROM Job_Application__c];
        
        // Build paginated query
        String query = 'SELECT Id, Company_Name__c, Position_Title__c, Status__c, Salary__c, Application_Date__c FROM Job_Application__c';
        
        if (String.isNotBlank(sortField)) {
            query += ' ORDER BY ' + sortField;
        } else {
            query += ' ORDER BY Application_Date__c DESC';
        }
        
        query += ' LIMIT ' + pageSize + ' OFFSET ' + offset;
        
        List<Job_Application__c> records = Database.query(query);
        
        // Calculate pagination metadata
        Integer totalPages = (Integer) Math.ceil((Decimal) totalRecords / pageSize);
        Boolean hasNext = pageNumber < totalPages;
        Boolean hasPrevious = pageNumber > 1;
        
        return new PaginationResult(
            records, 
            totalRecords, 
            totalPages, 
            pageNumber, 
            pageSize, 
            hasNext, 
            hasPrevious
        );
    }
    
    /**
     * @description Demonstrates query performance monitoring
     * @param queryType Type of query being monitored
     * @param recordCount Number of records processed
     * @return QueryPerformanceMetrics Performance metrics
     */
    public static QueryPerformanceMetrics monitorQueryPerformance(String queryType, Integer recordCount) {
        Integer startQueries = Limits.getQueries();
        Integer startCpuTime = Limits.getCpuTime();
        Integer startHeapSize = Limits.getHeapSize();
        Long startTime = System.currentTimeMillis();
        
        // Simulate query execution time
        System.debug('QueryOptimizationService: Monitoring query performance for ' + queryType);
        
        Long executionTime = System.currentTimeMillis() - startTime;
        Integer queriesUsed = Limits.getQueries() - startQueries;
        Integer cpuTimeUsed = Limits.getCpuTime() - startCpuTime;
        Integer heapSizeUsed = Limits.getHeapSize() - startHeapSize;
        
        return new QueryPerformanceMetrics(
            queryType,
            recordCount,
            executionTime,
            queriesUsed,
            cpuTimeUsed,
            heapSizeUsed
        );
    }
    
    /**
     * @description Wrapper class for pagination results
     */
    public class PaginationResult {
        @AuraEnabled public List<Job_Application__c> records { get; set; }
        @AuraEnabled public Integer totalRecords { get; set; }
        @AuraEnabled public Integer totalPages { get; set; }
        @AuraEnabled public Integer currentPage { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Boolean hasNext { get; set; }
        @AuraEnabled public Boolean hasPrevious { get; set; }
        
        public PaginationResult(List<Job_Application__c> records, Integer totalRecords, 
                               Integer totalPages, Integer currentPage, Integer pageSize,
                               Boolean hasNext, Boolean hasPrevious) {
            this.records = records;
            this.totalRecords = totalRecords;
            this.totalPages = totalPages;
            this.currentPage = currentPage;
            this.pageSize = pageSize;
            this.hasNext = hasNext;
            this.hasPrevious = hasPrevious;
        }
    }
    
    /**
     * @description Wrapper class for query performance metrics
     */
    public class QueryPerformanceMetrics {
        @AuraEnabled public String queryType { get; set; }
        @AuraEnabled public Integer recordCount { get; set; }
        @AuraEnabled public Long executionTime { get; set; }
        @AuraEnabled public Integer queriesUsed { get; set; }
        @AuraEnabled public Integer cpuTimeUsed { get; set; }
        @AuraEnabled public Integer heapSizeUsed { get; set; }
        @AuraEnabled public Decimal recordsPerMs { get; set; }
        @AuraEnabled public Decimal recordsPerQuery { get; set; }
        
        public QueryPerformanceMetrics(String queryType, Integer recordCount, Long executionTime,
                                     Integer queriesUsed, Integer cpuTimeUsed, Integer heapSizeUsed) {
            this.queryType = queryType;
            this.recordCount = recordCount;
            this.executionTime = executionTime;
            this.queriesUsed = queriesUsed;
            this.cpuTimeUsed = cpuTimeUsed;
            this.heapSizeUsed = heapSizeUsed;
            
            // Calculate efficiency metrics
            this.recordsPerMs = executionTime > 0 ? recordCount / executionTime : 0;
            this.recordsPerQuery = queriesUsed > 0 ? recordCount / queriesUsed : 0;
        }
    }
}