# 🧪 Testing Mastery Guide
*From Test Novice to Testing Ninja - Master the Art of Bulletproof Code*

---

## 🎯 **The Testing Mindset**

### **Why Testing is Your Superpower**
Testing isn't just about meeting the 75% coverage requirement - it's about:
- **Confidence** - Deploy without fear
- **Documentation** - Tests show how your code should work
- **Regression Prevention** - Catch bugs before users do
- **Design Improvement** - Hard-to-test code is usually bad code

### **The Testing Pyramid for Salesforce**
```
                    /\
                   /  \
              Manual Testing
                 /      \
                /        \
           Integration     \
              Tests        \
             /              \
            /                \
       Unit Tests         Bulk Tests
      /                            \
     /                              \
Test Data Setup              Governor Limit Tests
```

---

## 🏗️ **Test Architecture Patterns**

### **🎯 The AAA Pattern (Arrange, Act, Assert)**

```apex
@isTest
static void testSalaryCalculationWithValidInput() {
    // ARRANGE - Set up test data
    Job_Application__c testJob = new Job_Application__c(
        Company_Name__c = 'Test Company',
        Position_Title__c = 'Developer',
        Status__c = 'Saved',
        Salary__c = 100000
    );
    
    // ACT - Execute the functionality
    Test.startTest();
    insert testJob;
    Test.stopTest();
    
    // ASSERT - Verify the results
    Job_Application__c result = [SELECT Take_Home_Pay_Yearly__c FROM Job_Application__c WHERE Id = :testJob.Id];
    System.assertNotEquals(null, result.Take_Home_Pay_Yearly__c, 'Take-home pay should be calculated');
    System.assert(result.Take_Home_Pay_Yearly__c < 100000, 'Take-home should be less than gross');
}
```

### **🎯 Test Data Factory Pattern**

```apex
@isTest
public class TestDataFactory {
    
    public static Job_Application__c createJobApplication(String status, Decimal salary) {
        return new Job_Application__c(
            Company_Name__c = 'Test Company ' + Math.random(),
            Position_Title__c = 'Test Position',
            Status__c = status,
            Salary__c = salary,
            Location__c = 'Remote',
            Rating__c = '4'
        );
    }
    
    public static List<Job_Application__c> createJobApplications(Integer count, String status, Decimal baseSalary) {
        List<Job_Application__c> jobs = new List<Job_Application__c>();
        for (Integer i = 0; i < count; i++) {
            jobs.add(createJobApplication(status, baseSalary + (i * 1000)));
        }
        return jobs;
    }
    
    public static Account createTestAccount(String name) {
        return new Account(Name = name);
    }
    
    public static Contact createTestContact(Id accountId, String firstName, String lastName) {
        return new Contact(
            AccountId = accountId,
            FirstName = firstName,
            LastName = lastName,
            Email = firstName.toLowerCase() + '.' + lastName.toLowerCase() + '@testcompany.com'
        );
    }
}
```

---

## 🎯 **Testing Strategies by Component**

### **🧪 Testing Triggers and Handlers**

#### **The Complete Trigger Test Suite**
```apex
@isTest
public class JobApplicationTriggerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create reusable test data
        Account testAccount = TestDataFactory.createTestAccount('Test Company Inc');
        insert testAccount;
        
        Contact testContact = TestDataFactory.createTestContact(testAccount.Id, 'John', 'Doe');
        insert testContact;
    }
    
    // Test 1: Basic functionality
    @isTest
    static void testTaskCreationOnInsert() {
        Job_Application__c job = TestDataFactory.createJobApplication('Saved', 75000);
        
        Test.startTest();
        insert job;
        Test.stopTest();
        
        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :job.Id];
        System.assertEquals(3, tasks.size(), 'Should create 3 tasks for Saved status');
    }
    
    // Test 2: Status change scenarios
    @isTest
    static void testStatusChangeTaskCreation() {
        Job_Application__c job = TestDataFactory.createJobApplication('Saved', 75000);
        insert job;
        
        // Clear initial tasks
        delete [SELECT Id FROM Task WHERE WhatId = :job.Id];
        
        Test.startTest();
        job.Status__c = 'Applying';
        update job;
        Test.stopTest();
        
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :job.Id];
        System.assertEquals(5, tasks.size(), 'Should create 5 tasks for Applying status');
    }
    
    // Test 3: Bulk processing
    @isTest
    static void testBulkProcessing() {
        List<Job_Application__c> jobs = TestDataFactory.createJobApplications(200, 'Saved', 50000);
        
        Test.startTest();
        insert jobs;
        Test.stopTest();
        
        List<Task> allTasks = [SELECT Id FROM Task WHERE WhatId IN :jobs];
        System.assertEquals(600, allTasks.size(), 'Should create 3 tasks per job (200 * 3)');
    }
    
    // Test 4: Edge cases
    @isTest
    static void testEdgeCases() {
        // Test with null salary
        Job_Application__c jobWithoutSalary = TestDataFactory.createJobApplication('Saved', null);
        
        Test.startTest();
        insert jobWithoutSalary;
        Test.stopTest();
        
        Job_Application__c result = [SELECT Take_Home_Pay_Yearly__c FROM Job_Application__c WHERE Id = :jobWithoutSalary.Id];
        System.assertEquals(null, result.Take_Home_Pay_Yearly__c, 'Should not calculate take-home for null salary');
    }
    
    // Test 5: Error scenarios
    @isTest
    static void testErrorHandling() {
        // Test with invalid data that might cause exceptions
        Job_Application__c invalidJob = new Job_Application__c(
            // Missing required fields intentionally
            Status__c = 'Saved'
        );
        
        Test.startTest();
        try {
            insert invalidJob;
            System.assert(false, 'Should have thrown an exception');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('REQUIRED_FIELD_MISSING'), 'Should fail due to missing required fields');
        }
        Test.stopTest();
    }
}
```

### **🧪 Testing Service Classes**

#### **Isolated Service Testing**
```apex
@isTest
public class SalaryCalculationServiceTest {
    
    @isTest
    static void testFederalTaxCalculation() {
        // Test specific tax brackets
        Decimal result1 = SalaryCalculationService.calculateFederalIncomeTax(50000);
        Decimal result2 = SalaryCalculationService.calculateFederalIncomeTax(100000);
        
        System.assert(result1 > 0, 'Should calculate tax for $50k');
        System.assert(result2 > result1, 'Higher income should have higher tax');
        
        // Test edge cases
        System.assertEquals(0, SalaryCalculationService.calculateFederalIncomeTax(0), 'Zero income should have zero tax');
        System.assertEquals(0, SalaryCalculationService.calculateFederalIncomeTax(null), 'Null income should have zero tax');
    }
    
    @isTest
    static void testSocialSecurityTaxCalculation() {
        // Test normal case
        Decimal result = SalaryCalculationService.calculateSocialSecurityTax(50000);
        Decimal expected = 50000 * 0.062; // 6.2%
        System.assertEquals(expected, result, 'Should calculate 6.2% of income');
        
        // Test wage base limit
        Decimal highIncomeResult = SalaryCalculationService.calculateSocialSecurityTax(200000);
        Decimal expectedCapped = 160200 * 0.062; // Capped at wage base
        System.assertEquals(expectedCapped, highIncomeResult, 'Should cap at wage base limit');
    }
    
    @isTest
    static void testCompleteCalculationFlow() {
        List<Job_Application__c> testJobs = new List<Job_Application__c>{
            TestDataFactory.createJobApplication('Saved', 50000),
            TestDataFactory.createJobApplication('Saved', 100000),
            TestDataFactory.createJobApplication('Saved', 200000)
        };
        
        Test.startTest();
        SalaryCalculationService.calculateTakeHomePay(testJobs);
        Test.stopTest();
        
        for (Job_Application__c job : testJobs) {
            System.assertNotEquals(null, job.Federal_Tax__c, 'Federal tax should be calculated');
            System.assertNotEquals(null, job.Take_Home_Pay_Yearly__c, 'Take-home pay should be calculated');
            System.assert(job.Take_Home_Pay_Yearly__c < job.Salary__c, 'Take-home should be less than gross');
        }
    }
}
```

---

## 🎯 **Advanced Testing Techniques**

### **🧪 Mock Testing for External Dependencies**

```apex
// Mock class for testing API callouts
@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"jobs": [{"title": "Test Job", "company": "Test Company"}]}');
        res.setStatusCode(200);
        return res;
    }
}

@isTest
static void testApiIntegration() {
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    
    Test.startTest();
    // Your API callout code here
    Test.stopTest();
    
    // Assertions
}
```

### **🧪 Testing Asynchronous Operations**

```apex
@isTest
static void testBatchJob() {
    // Setup test data
    List<Job_Application__c> staleJobs = TestDataFactory.createJobApplications(50, 'Applied', 75000);
    for (Job_Application__c job : staleJobs) {
        job.Follow_Up_Date__c = Date.today().addDays(-35); // Make them stale
    }
    insert staleJobs;
    
    Test.startTest();
    // Execute batch job
    StaleJobCleanupBatch batch = new StaleJobCleanupBatch();
    Database.executeBatch(batch);
    Test.stopTest();
    
    // Verify results
    List<Job_Application__c> updatedJobs = [SELECT Status__c FROM Job_Application__c WHERE Id IN :staleJobs];
    for (Job_Application__c job : updatedJobs) {
        System.assertEquals('Closed', job.Status__c, 'Stale jobs should be closed');
    }
}
```

### **🧪 Testing Scheduled Jobs**

```apex
@isTest
static void testScheduledJob() {
    Test.startTest();
    
    String cronExp = '0 0 0 15 3 ? 2025'; // March 15, 2025 at midnight
    String jobId = System.schedule('Test Scheduled Job', cronExp, new InterviewReminderScheduler());
    
    Test.stopTest();
    
    // Verify job was scheduled
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
    System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match');
    System.assertEquals(0, ct.TimesTriggered, 'Job should not have run yet');
}
```

---

## 🎯 **Performance Testing Strategies**

### **🧪 Governor Limit Testing**

```apex
@isTest
static void testGovernorLimits() {
    // Test SOQL limits
    List<Job_Application__c> jobs = TestDataFactory.createJobApplications(200, 'Saved', 50000);
    
    Test.startTest();
    
    Integer soqlBefore = Limits.getQueries();
    insert jobs;
    Integer soqlAfter = Limits.getQueries();
    
    Test.stopTest();
    
    System.assert(soqlAfter - soqlBefore <= 10, 'Should use minimal SOQL queries: ' + (soqlAfter - soqlBefore));
    
    // Test DML limits
    System.assert(Limits.getDmlStatements() <= 10, 'Should use minimal DML statements');
    System.assert(Limits.getDmlRows() <= 10000, 'Should not exceed DML row limits');
}
```

### **🧪 CPU Time Testing**

```apex
@isTest
static void testCpuPerformance() {
    List<Job_Application__c> jobs = TestDataFactory.createJobApplications(200, 'Saved', 100000);
    
    Test.startTest();
    Long startTime = System.currentTimeMillis();
    
    insert jobs;
    
    Long endTime = System.currentTimeMillis();
    Test.stopTest();
    
    Long executionTime = endTime - startTime;
    System.assert(executionTime < 5000, 'Bulk operation should complete in under 5 seconds: ' + executionTime + 'ms');
}
```

---

## 🎯 **Test Data Management**

### **🧪 Test Data Isolation**

```apex
@isTest
public class IsolatedTestClass {
    
    // Use @TestSetup for shared data
    @TestSetup
    static void setupSharedData() {
        // Data that multiple test methods need
        Account sharedAccount = TestDataFactory.createTestAccount('Shared Company');
        insert sharedAccount;
    }
    
    @isTest
    static void testMethod1() {
        // This test can access shared data
        Account acc = [SELECT Id FROM Account WHERE Name = 'Shared Company'];
        
        // Create test-specific data
        Job_Application__c job = TestDataFactory.createJobApplication('Saved', 75000);
        insert job;
        
        // Test logic here
    }
    
    @isTest
    static void testMethod2() {
        // This test also has access to shared data
        // But cannot see data created in testMethod1
    }
}
```

### **🧪 Test Data Cleanup**

```apex
@isTest
static void testWithCleanup() {
    // Create test data
    List<Job_Application__c> testJobs = TestDataFactory.createJobApplications(10, 'Saved', 50000);
    insert testJobs;
    
    try {
        Test.startTest();
        // Your test logic here
        Test.stopTest();
        
        // Assertions
        
    } finally {
        // Cleanup (though Salesforce does this automatically in tests)
        delete testJobs;
    }
}
```

---

## 🎯 **Testing Best Practices Checklist**

### **✅ Code Coverage Best Practices**
- [ ] Every trigger has a test class
- [ ] Every Apex class has a test class
- [ ] Test both positive and negative scenarios
- [ ] Test bulk operations (200+ records)
- [ ] Test edge cases and boundary conditions
- [ ] Use meaningful assertions with custom messages

### **✅ Test Organization**
- [ ] Test classes follow naming convention (ClassNameTest)
- [ ] Use @TestSetup for shared test data
- [ ] Group related tests in the same class
- [ ] Use descriptive test method names
- [ ] Add comments explaining complex test scenarios

### **✅ Performance Testing**
- [ ] Test governor limit compliance
- [ ] Verify bulk operation performance
- [ ] Test with realistic data volumes
- [ ] Monitor CPU time usage
- [ ] Check memory consumption

### **✅ Integration Testing**
- [ ] Test trigger interactions
- [ ] Test service class integration
- [ ] Test end-to-end workflows
- [ ] Test error propagation
- [ ] Test rollback scenarios

---

## 🏆 **Testing Mastery Levels**

### **🥉 Bronze Level: Basic Coverage**
- All classes have test methods
- 75%+ code coverage achieved
- Basic positive test cases

### **🥈 Silver Level: Comprehensive Testing**
- Positive and negative test cases
- Bulk operation testing
- Edge case coverage
- Meaningful assertions

### **🥇 Gold Level: Testing Excellence**
- Performance testing
- Integration testing
- Mock testing for dependencies
- Test data factories
- Comprehensive documentation

### **💎 Platinum Level: Testing Ninja**
- Advanced testing patterns
- Custom test frameworks
- Automated test execution
- Test-driven development
- Mentoring others in testing

---

## 🚀 **Next Level: Test-Driven Development (TDD)**

### **The TDD Cycle**
```
1. Write a failing test (Red)
2. Write minimal code to pass (Green)
3. Refactor and improve (Refactor)
4. Repeat
```

### **TDD Example**
```apex
// Step 1: Write failing test
@isTest
static void testCalculateMonthlyTakeHome() {
    Job_Application__c job = TestDataFactory.createJobApplication('Saved', 120000);
    
    Test.startTest();
    SalaryCalculationService.calculateTakeHomePay(new List<Job_Application__c>{job});
    Test.stopTest();
    
    System.assertNotEquals(null, job.Take_Home_Pay_Monthly__c, 'Monthly take-home should be calculated');
    System.assertEquals(job.Take_Home_Pay_Yearly__c / 12, job.Take_Home_Pay_Monthly__c, 'Monthly should be yearly divided by 12');
}

// Step 2: Write code to make it pass
// Step 3: Refactor and improve
```

---

## 🎉 **Congratulations: You're Now a Testing Master!**

You've learned:
- **Testing Fundamentals** - AAA pattern, test data management
- **Advanced Techniques** - Mocking, async testing, performance testing
- **Best Practices** - Organization, coverage, integration
- **Team Leadership** - How to guide others in testing excellence

**Your testing skills will:**
- Give you confidence in your code
- Impress your teammates and reviewers
- Prevent bugs from reaching users
- Make you a more valuable developer

**Ready for Week 3?** Your solid testing foundation will make Lightning Web Component development much smoother! ⚡🧪

---

*Remember: Good tests are like good friends - they're there when you need them most!* 🤝
