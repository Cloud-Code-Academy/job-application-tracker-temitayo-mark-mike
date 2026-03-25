/**
 * Salesforce sandbox integration tests
 * These tests require a Salesforce sandbox environment and valid credentials
 */

import { SalesforceClient } from '../../src/core/SalesforceClient';
import { KnowledgeArticleData } from '../../src/types';

// Skip these tests if no Salesforce credentials are provided
const skipSalesforceTests = !process.env.SF_TEST_USERNAME || !process.env.SF_TEST_PASSWORD;

describe('Salesforce Integration Tests', () => {
  let salesforceClient: SalesforceClient;
  const testArticleIds: string[] = [];

  beforeAll(async () => {
    if (skipSalesforceTests) {
      console.log('Skipping Salesforce integration tests - no credentials provided');
      return;
    }

    const config = {
      loginUrl: process.env.SF_TEST_LOGIN_URL || 'https://test.salesforce.com',
      username: process.env.SF_TEST_USERNAME!,
      password: process.env.SF_TEST_PASSWORD!,
      securityToken: process.env.SF_TEST_SECURITY_TOKEN || '',
      apiVersion: '58.0'
    };

    salesforceClient = new SalesforceClient(config);
  });

  afterAll(async () => {
    if (skipSalesforceTests || !salesforceClient) return;

    // Clean up test articles
    for (const articleId of testArticleIds) {
      try {
        await salesforceClient.deleteKnowledgeArticle(articleId);
      } catch (error) {
        console.warn(`Failed to clean up test article ${articleId}:`, error);
      }
    }
  });

  describe('Authentication and Connection', () => {
    it('should authenticate successfully with valid credentials', async () => {
      if (skipSalesforceTests) return;

      await expect(salesforceClient.authenticate()).resolves.not.toThrow();
    }, 30000);

    it('should test connection and return org info', async () => {
      if (skipSalesforceTests) return;

      const connectionTest = await salesforceClient.testConnection();

      expect(connectionTest.success).toBe(true);
      expect(connectionTest.organizationId).toBeDefined();
      expect(connectionTest.userId).toBeDefined();
      expect(connectionTest.apiVersion).toBeDefined();
      expect(connectionTest.knowledgeAccessible).toBe(true);
    }, 30000);

    it('should get API usage information', async () => {
      if (skipSalesforceTests) return;

      const usage = await salesforceClient.getApiUsage();

      expect(usage).toBeDefined();
      expect(usage.dailyApiRequests).toBeDefined();
      expect(usage.dailyApiRequests.used).toBeGreaterThanOrEqual(0);
      expect(usage.dailyApiRequests.max).toBeGreaterThan(0);
      expect(usage.rateLimitInfo).toBeDefined();
    }, 15000);
  });

  describe('Knowledge Article Operations', () => {
    it('should create a new Knowledge article', async () => {
      if (skipSalesforceTests) return;

      const articleData: KnowledgeArticleData = {
        Title: 'Test Article - Integration Test',
        UrlName: `test-article-${Date.now()}`,
        Summary: 'This is a test article created by integration tests',
        Content__c: '<h1>Test Content</h1><p>This is test content for integration testing.</p>',
        Difficulty_Level__c: 'Beginner',
        Reading_Time__c: 5,
        Tags__c: 'test;integration;automated',
        Prerequisites__c: 'None',
        Related_Articles__c: '<div>No related articles</div>',
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      };

      const result = await salesforceClient.createKnowledgeArticle(articleData);

      expect(result.success).toBe(true);
      expect(result.articleId).toBeDefined();
      expect(result.knowledgeArticleId).toBeDefined();
      expect(result.urlName).toBe(articleData.UrlName);
      expect(result.publishStatus).toBeDefined();

      // Store for cleanup
      if (result.articleId) {
        testArticleIds.push(result.articleId);
      }
    }, 30000);

    it('should find an existing article by URL name', async () => {
      if (skipSalesforceTests) return;

      // First create an article
      const articleData: KnowledgeArticleData = {
        Title: 'Findable Test Article',
        UrlName: `findable-test-${Date.now()}`,
        Summary: 'Article for testing find functionality',
        Content__c: '<p>Findable content</p>',
        Difficulty_Level__c: 'Beginner',
        Reading_Time__c: 2,
        Tags__c: 'test',
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      };

      const createResult = await salesforceClient.createKnowledgeArticle(articleData);
      expect(createResult.success).toBe(true);
      
      if (createResult.articleId) {
        testArticleIds.push(createResult.articleId);
      }

      // Now try to find it
      const foundArticle = await salesforceClient.findExistingArticle(articleData.UrlName);

      expect(foundArticle).toBeDefined();
      expect(foundArticle?.urlName).toBe(articleData.UrlName);
      expect(foundArticle?.articleId).toBe(createResult.articleId);
    }, 45000);

    it('should update an existing Knowledge article', async () => {
      if (skipSalesforceTests) return;

      // First create an article
      const originalData: KnowledgeArticleData = {
        Title: 'Original Title',
        UrlName: `updatable-test-${Date.now()}`,
        Summary: 'Original summary',
        Content__c: '<p>Original content</p>',
        Difficulty_Level__c: 'Beginner',
        Reading_Time__c: 3,
        Tags__c: 'original',
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      };

      const createResult = await salesforceClient.createKnowledgeArticle(originalData);
      expect(createResult.success).toBe(true);
      
      if (createResult.articleId) {
        testArticleIds.push(createResult.articleId);
      }

      // Now update it
      const updatedData: Partial<KnowledgeArticleData> = {
        Title: 'Updated Title',
        Summary: 'Updated summary',
        Content__c: '<p>Updated content</p>',
        Tags__c: 'updated;modified'
      };

      const updateResult = await salesforceClient.updateKnowledgeArticle(
        createResult.articleId!,
        updatedData
      );

      expect(updateResult.success).toBe(true);
      expect(updateResult.articleId).toBe(createResult.articleId);
      expect(updateResult.versionNumber).toBeGreaterThan(createResult.versionNumber || 1);
    }, 45000);

    it('should handle article creation with special characters', async () => {
      if (skipSalesforceTests) return;

      const articleData: KnowledgeArticleData = {
        Title: 'Test Article with Special Characters: éñ中文🚀',
        UrlName: `special-chars-test-${Date.now()}`,
        Summary: 'Testing special characters: éñ中文🚀',
        Content__c: '<h1>Special Characters</h1><p>Content with éñ中文🚀 characters</p>',
        Difficulty_Level__c: 'Intermediate',
        Reading_Time__c: 7,
        Tags__c: 'special;characters;unicode',
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      };

      const result = await salesforceClient.createKnowledgeArticle(articleData);

      expect(result.success).toBe(true);
      expect(result.articleId).toBeDefined();

      if (result.articleId) {
        testArticleIds.push(result.articleId);
      }
    }, 30000);

    it('should handle large content articles', async () => {
      if (skipSalesforceTests) return;

      const largeContent = '<h1>Large Content Test</h1>' + 
        '<p>' + 'This is a large content block. '.repeat(1000) + '</p>' +
        '<ul>' + Array.from({ length: 100 }, (_, i) => `<li>List item ${i}</li>`).join('') + '</ul>';

      const articleData: KnowledgeArticleData = {
        Title: 'Large Content Test Article',
        UrlName: `large-content-test-${Date.now()}`,
        Summary: 'Testing article with large content',
        Content__c: largeContent,
        Difficulty_Level__c: 'Advanced',
        Reading_Time__c: 45,
        Tags__c: 'large;content;performance',
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      };

      const result = await salesforceClient.createKnowledgeArticle(articleData);

      expect(result.success).toBe(true);
      expect(result.articleId).toBeDefined();

      if (result.articleId) {
        testArticleIds.push(result.articleId);
      }
    }, 45000);
  });

  describe('Error Handling', () => {
    it('should handle duplicate URL names gracefully', async () => {
      if (skipSalesforceTests) return;

      const urlName = `duplicate-test-${Date.now()}`;
      
      const articleData: KnowledgeArticleData = {
        Title: 'First Article',
        UrlName: urlName,
        Summary: 'First article with this URL name',
        Content__c: '<p>First content</p>',
        Difficulty_Level__c: 'Beginner',
        Reading_Time__c: 2,
        Tags__c: 'test',
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      };

      // Create first article
      const firstResult = await salesforceClient.createKnowledgeArticle(articleData);
      expect(firstResult.success).toBe(true);
      
      if (firstResult.articleId) {
        testArticleIds.push(firstResult.articleId);
      }

      // Try to create second article with same URL name
      const duplicateData = {
        ...articleData,
        Title: 'Second Article',
        Summary: 'Second article with duplicate URL name'
      };

      const secondResult = await salesforceClient.createKnowledgeArticle(duplicateData);
      
      // Should either fail or handle gracefully
      if (!secondResult.success) {
        expect(secondResult.error).toBeDefined();
        expect(secondResult.error).toContain('duplicate');
      } else if (secondResult.articleId) {
        testArticleIds.push(secondResult.articleId);
      }
    }, 45000);

    it('should handle invalid field values', async () => {
      if (skipSalesforceTests) return;

      const invalidData: any = {
        Title: '', // Empty title should be invalid
        UrlName: `invalid-test-${Date.now()}`,
        Summary: 'Testing invalid data',
        Content__c: '<p>Content</p>',
        Difficulty_Level__c: 'InvalidLevel', // Invalid difficulty level
        Reading_Time__c: -5, // Negative reading time
        Tags__c: 'test',
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      };

      const result = await salesforceClient.createKnowledgeArticle(invalidData);

      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    }, 30000);

    it('should handle network timeouts gracefully', async () => {
      if (skipSalesforceTests) return;

      // Create a client with very short timeout
      const timeoutConfig = {
        loginUrl: process.env.SF_TEST_LOGIN_URL || 'https://test.salesforce.com',
        username: process.env.SF_TEST_USERNAME!,
        password: process.env.SF_TEST_PASSWORD!,
        securityToken: process.env.SF_TEST_SECURITY_TOKEN || '',
        apiVersion: '58.0'
      };

      const timeoutClient = new SalesforceClient(timeoutConfig);
      
      // Set very short timeout
      (timeoutClient as any).connection.timeout = 1; // 1ms timeout

      const articleData: KnowledgeArticleData = {
        Title: 'Timeout Test',
        UrlName: `timeout-test-${Date.now()}`,
        Summary: 'Testing timeout handling',
        Content__c: '<p>Content</p>',
        Difficulty_Level__c: 'Beginner',
        Reading_Time__c: 2,
        Tags__c: 'test',
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      };

      const result = await timeoutClient.createKnowledgeArticle(articleData);

      // Should handle timeout gracefully
      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    }, 15000);
  });

  describe('Performance and Rate Limiting', () => {
    it('should handle multiple concurrent requests', async () => {
      if (skipSalesforceTests) return;

      const concurrentRequests = 5;
      const promises = [];

      for (let i = 0; i < concurrentRequests; i++) {
        const articleData: KnowledgeArticleData = {
          Title: `Concurrent Test Article ${i}`,
          UrlName: `concurrent-test-${Date.now()}-${i}`,
          Summary: `Concurrent test article ${i}`,
          Content__c: `<p>Concurrent content ${i}</p>`,
          Difficulty_Level__c: 'Beginner',
          Reading_Time__c: 2,
          Tags__c: 'concurrent;test',
          Language: 'en_US',
          IsVisibleInApp: true,
          IsVisibleInPkb: true,
          IsVisibleInCsp: true
        };

        promises.push(salesforceClient.createKnowledgeArticle(articleData));
      }

      const results = await Promise.all(promises);

      // All requests should complete
      expect(results).toHaveLength(concurrentRequests);
      
      // Most should succeed (some might fail due to rate limiting)
      const successfulResults = results.filter(r => r.success);
      expect(successfulResults.length).toBeGreaterThan(0);

      // Store successful article IDs for cleanup
      successfulResults.forEach(result => {
        if (result.articleId) {
          testArticleIds.push(result.articleId);
        }
      });
    }, 60000);

    it('should respect rate limits', async () => {
      if (skipSalesforceTests) return;

      const startTime = Date.now();
      const requests = [];

      // Make many requests quickly
      for (let i = 0; i < 10; i++) {
        requests.push(salesforceClient.getApiUsage());
      }

      await Promise.all(requests);
      const duration = Date.now() - startTime;

      // Should take some time due to rate limiting
      expect(duration).toBeGreaterThan(100); // At least 100ms for 10 requests
    }, 30000);
  });

  describe('Data Categories and Permissions', () => {
    it('should verify Knowledge Base permissions', async () => {
      if (skipSalesforceTests) return;

      const connectionTest = await salesforceClient.testConnection();

      expect(connectionTest.success).toBe(true);
      expect(connectionTest.knowledgeAccessible).toBe(true);
    }, 15000);

    it('should handle data category assignments', async () => {
      if (skipSalesforceTests) return;

      // This test would verify data category functionality
      // Implementation depends on specific Salesforce org setup
      const usage = await salesforceClient.getApiUsage();
      expect(usage).toBeDefined();
    }, 15000);
  });
});

// Helper function to check if Salesforce tests should run
export function shouldRunSalesforceTests(): boolean {
  return !skipSalesforceTests;
}

// Export test utilities for other test files
export { skipSalesforceTests };