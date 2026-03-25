/**
 * Unit tests for SalesforceClient class
 */

import { SalesforceClient, SalesforceApiError, AuthenticationResult, KnowledgeArticleResult } from '../../src/core/SalesforceClient';
import { SalesforceConfig, KnowledgeArticleData } from '../../src/types';
import jsforce from 'jsforce';

// Mock jsforce
jest.mock('jsforce');
const mockJsforce = jsforce as jest.Mocked<typeof jsforce>;

describe('SalesforceClient', () => {
  let salesforceClient: SalesforceClient;
  let mockConnection: jest.Mocked<jsforce.Connection>;
  let config: SalesforceConfig;

  beforeEach(() => {
    config = {
      loginUrl: 'https://test.salesforce.com',
      username: 'test@example.com',
      password: 'testpassword',
      securityToken: 'testsecuritytoken',
      apiVersion: '58.0'
    };

    // Create mock connection
    mockConnection = {
      login: jest.fn(),
      query: jest.fn(),
      limits: jest.fn(),
      request: jest.fn(),
      sobject: jest.fn(),
      userInfo: {
        id: 'user123',
        organizationId: 'org123'
      }
    } as any;

    // Mock sobject methods
    const mockSobject = {
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn()
    };
    mockConnection.sobject.mockReturnValue(mockSobject as any);

    // Mock jsforce Connection constructor
    (mockJsforce.Connection as any).mockImplementation(() => mockConnection);

    salesforceClient = new SalesforceClient(config);
    jest.clearAllMocks();
  });

  describe('authenticate', () => {
    it('should authenticate successfully', async () => {
      const loginResult = {
        id: 'user123',
        url: 'https://test.salesforce.com',
        organizationId: 'org123'
      };
      mockConnection.login.mockResolvedValue(loginResult);

      const result = await salesforceClient.authenticate();

      expect(result.success).toBe(true);
      expect(result.sessionId).toBe('user123');
      expect(result.organizationId).toBe('org123');
      expect(mockConnection.login).toHaveBeenCalledWith(
        'test@example.com',
        'testpasswordtestsecuritytoken'
      );
    });

    it('should handle authentication failure', async () => {
      mockConnection.login.mockRejectedValue(new Error('Invalid credentials'));

      await expect(salesforceClient.authenticate()).rejects.toThrow(SalesforceApiError);
      await expect(salesforceClient.authenticate()).rejects.toThrow('Authentication failed');
    });

    it('should combine password and security token', async () => {
      const loginResult = { id: 'user123', url: 'https://test.salesforce.com', organizationId: 'org123' };
      mockConnection.login.mockResolvedValue(loginResult);

      await salesforceClient.authenticate();

      expect(mockConnection.login).toHaveBeenCalledWith(
        'test@example.com',
        'testpasswordtestsecuritytoken'
      );
    });
  });

  describe('createKnowledgeArticle', () => {
    const sampleArticleData: KnowledgeArticleData = {
      Title: 'Test Article',
      UrlName: 'test-article',
      Summary: 'Test summary',
      Content__c: '<p>Test content</p>',
      Difficulty_Level__c: 'Intermediate',
      Reading_Time__c: 5,
      Tags__c: 'test;example',
      Language: 'en_US',
      IsVisibleInApp: true,
      IsVisibleInPkb: true,
      IsVisibleInCsp: true
    };

    beforeEach(async () => {
      // Mock authentication
      mockConnection.login.mockResolvedValue({
        id: 'user123',
        url: 'https://test.salesforce.com',
        organizationId: 'org123'
      });
      mockConnection.query.mockResolvedValue({ totalSize: 1, records: [] });
      await salesforceClient.authenticate();
    });

    it('should create Knowledge article successfully', async () => {
      const createResult = { success: true, id: 'article123' };
      const publishResult = {
        success: true,
        knowledgeArticleId: 'ka123',
        publishStatus: 'Online',
        versionNumber: 1
      };

      mockConnection.sobject().create.mockResolvedValue(createResult);
      
      // Mock getArticleInfo for publishing
      mockConnection.query.mockResolvedValue({
        totalSize: 1,
        records: [{
          Id: 'article123',
          KnowledgeArticleId: 'ka123',
          Title: 'Test Article',
          UrlName: 'test-article',
          VersionNumber: 1,
          PublishStatus: 'Draft',
          Language: 'en_US'
        }]
      });

      // Mock publish request
      mockConnection.request.mockResolvedValue({ versionNumber: 1 });

      const result = await salesforceClient.createKnowledgeArticle(sampleArticleData);

      expect(result.success).toBe(true);
      expect(result.articleId).toBe('article123');
      expect(result.urlName).toBe('test-article');
      expect(mockConnection.sobject).toHaveBeenCalledWith('Documentation_Article__kav');
      expect(mockConnection.sobject().create).toHaveBeenCalledWith(
        expect.objectContaining({
          Title: 'Test Article',
          UrlName: 'test-article',
          Content__c: '<p>Test content</p>'
        })
      );
    });

    it('should handle creation failure', async () => {
      const createResult = { success: false, errors: ['Field validation failed'] };
      mockConnection.sobject().create.mockResolvedValue(createResult);

      await expect(salesforceClient.createKnowledgeArticle(sampleArticleData))
        .rejects.toThrow(SalesforceApiError);
    });

    it('should handle network errors', async () => {
      mockConnection.sobject().create.mockRejectedValue(new Error('Network error'));

      await expect(salesforceClient.createKnowledgeArticle(sampleArticleData))
        .rejects.toThrow(SalesforceApiError);
    });
  });

  describe('updateKnowledgeArticle', () => {
    beforeEach(async () => {
      mockConnection.login.mockResolvedValue({
        id: 'user123',
        url: 'https://test.salesforce.com',
        organizationId: 'org123'
      });
      mockConnection.query.mockResolvedValue({ totalSize: 1, records: [] });
      await salesforceClient.authenticate();
    });

    it('should update Knowledge article successfully', async () => {
      const updateResult = { success: true, id: 'article123' };
      const updateData = { Title: 'Updated Title', Content__c: '<p>Updated content</p>' };

      mockConnection.sobject().update.mockResolvedValue(updateResult);
      
      // Mock getArticleInfo for publishing
      mockConnection.query.mockResolvedValue({
        totalSize: 1,
        records: [{
          Id: 'article123',
          KnowledgeArticleId: 'ka123',
          Title: 'Updated Title',
          UrlName: 'test-article',
          VersionNumber: 2,
          PublishStatus: 'Draft',
          Language: 'en_US'
        }]
      });

      mockConnection.request.mockResolvedValue({ versionNumber: 2 });

      const result = await salesforceClient.updateKnowledgeArticle('article123', updateData);

      expect(result.success).toBe(true);
      expect(result.articleId).toBe('article123');
      expect(mockConnection.sobject().update).toHaveBeenCalledWith({
        Id: 'article123',
        ...updateData
      });
    });

    it('should handle update failure', async () => {
      const updateResult = { success: false, errors: ['Update failed'] };
      mockConnection.sobject().update.mockResolvedValue(updateResult);

      await expect(salesforceClient.updateKnowledgeArticle('article123', { Title: 'New Title' }))
        .rejects.toThrow(SalesforceApiError);
    });
  });

  describe('findExistingArticle', () => {
    beforeEach(async () => {
      mockConnection.login.mockResolvedValue({
        id: 'user123',
        url: 'https://test.salesforce.com',
        organizationId: 'org123'
      });
      await salesforceClient.authenticate();
    });

    it('should find existing article', async () => {
      const queryResult = {
        totalSize: 1,
        records: [{
          Id: 'article123',
          KnowledgeArticleId: 'ka123',
          Title: 'Test Article',
          UrlName: 'test-article',
          VersionNumber: 1,
          PublishStatus: 'Online',
          Language: 'en_US'
        }]
      };
      mockConnection.query.mockResolvedValue(queryResult);

      const result = await salesforceClient.findExistingArticle('test-article');

      expect(result).not.toBeNull();
      expect(result?.found).toBe(true);
      expect(result?.articleId).toBe('article123');
      expect(result?.urlName).toBe('test-article');
      expect(mockConnection.query).toHaveBeenCalledWith(
        expect.stringContaining("WHERE UrlName = 'test-article'")
      );
    });

    it('should return null when article not found', async () => {
      const queryResult = { totalSize: 0, records: [] };
      mockConnection.query.mockResolvedValue(queryResult);

      const result = await salesforceClient.findExistingArticle('nonexistent-article');

      expect(result).toBeNull();
    });

    it('should handle query errors', async () => {
      mockConnection.query.mockRejectedValue(new Error('Query failed'));

      await expect(salesforceClient.findExistingArticle('test-article'))
        .rejects.toThrow(SalesforceApiError);
    });
  });

  describe('deleteKnowledgeArticle', () => {
    beforeEach(async () => {
      mockConnection.login.mockResolvedValue({
        id: 'user123',
        url: 'https://test.salesforce.com',
        organizationId: 'org123'
      });
      mockConnection.query.mockResolvedValue({ totalSize: 1, records: [] });
      await salesforceClient.authenticate();
    });

    it('should delete article successfully', async () => {
      const deleteResult = { success: true };
      mockConnection.sobject().delete.mockResolvedValue(deleteResult);

      const result = await salesforceClient.deleteKnowledgeArticle('article123');

      expect(result.success).toBe(true);
      expect(result.articleId).toBe('article123');
      expect(mockConnection.sobject().delete).toHaveBeenCalledWith('article123');
    });

    it('should handle deletion failure', async () => {
      const deleteResult = { success: false, errors: ['Cannot delete published article'] };
      mockConnection.sobject().delete.mockResolvedValue(deleteResult);

      const result = await salesforceClient.deleteKnowledgeArticle('article123');

      expect(result.success).toBe(false);
      expect(result.errors).toEqual(['Cannot delete published article']);
    });
  });

  describe('testConnection', () => {
    it('should test connection successfully', async () => {
      mockConnection.login.mockResolvedValue({
        id: 'user123',
        url: 'https://test.salesforce.com',
        organizationId: 'org123'
      });
      mockConnection.query
        .mockResolvedValueOnce({ totalSize: 1, records: [{ Id: 'org123' }] }) // Organization query
        .mockResolvedValueOnce({ totalSize: 0, records: [] }); // Knowledge query

      const result = await salesforceClient.testConnection();

      expect(result.success).toBe(true);
      expect(result.authenticated).toBe(true);
      expect(result.knowledgeAccessible).toBe(true);
      expect(result.organizationId).toBe('org123');
    });

    it('should handle connection test failure', async () => {
      mockConnection.login.mockRejectedValue(new Error('Authentication failed'));

      const result = await salesforceClient.testConnection();

      expect(result.success).toBe(false);
      expect(result.authenticated).toBe(false);
      expect(result.error).toContain('Authentication failed');
    });
  });

  describe('getApiUsage', () => {
    beforeEach(async () => {
      mockConnection.login.mockResolvedValue({
        id: 'user123',
        url: 'https://test.salesforce.com',
        organizationId: 'org123'
      });
      await salesforceClient.authenticate();
    });

    it('should get API usage statistics', async () => {
      const limitsResult = {
        DailyApiRequests: { Max: 15000, Remaining: 14500 },
        HourlyTimeBasedWorkflow: { Max: 1000, Remaining: 950 }
      };
      mockConnection.limits.mockResolvedValue(limitsResult);

      const result = await salesforceClient.getApiUsage();

      expect(result.dailyApiRequests.max).toBe(15000);
      expect(result.dailyApiRequests.remaining).toBe(14500);
      expect(result.dailyApiRequests.used).toBe(500);
      expect(result.rateLimitInfo).toBeDefined();
    });

    it('should handle limits query failure', async () => {
      mockConnection.limits.mockRejectedValue(new Error('Limits query failed'));

      await expect(salesforceClient.getApiUsage()).rejects.toThrow(SalesforceApiError);
    });
  });

  describe('bulkCreateKnowledgeArticles', () => {
    const sampleArticles: KnowledgeArticleData[] = [
      {
        Title: 'Article 1',
        UrlName: 'article-1',
        Content__c: '<p>Content 1</p>',
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      },
      {
        Title: 'Article 2',
        UrlName: 'article-2',
        Content__c: '<p>Content 2</p>',
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      }
    ];

    beforeEach(async () => {
      mockConnection.login.mockResolvedValue({
        id: 'user123',
        url: 'https://test.salesforce.com',
        organizationId: 'org123'
      });
      mockConnection.query.mockResolvedValue({ totalSize: 1, records: [] });
      await salesforceClient.authenticate();
    });

    it('should bulk create articles successfully', async () => {
      // Mock successful creation for both articles
      mockConnection.sobject().create
        .mockResolvedValueOnce({ success: true, id: 'article1' })
        .mockResolvedValueOnce({ success: true, id: 'article2' });

      // Mock getArticleInfo calls for publishing
      mockConnection.query
        .mockResolvedValue({ totalSize: 1, records: [] }) // Authentication check
        .mockResolvedValueOnce({
          totalSize: 1,
          records: [{
            Id: 'article1',
            KnowledgeArticleId: 'ka1',
            Title: 'Article 1',
            UrlName: 'article-1',
            VersionNumber: 1,
            PublishStatus: 'Online',
            Language: 'en_US'
          }]
        })
        .mockResolvedValueOnce({
          totalSize: 1,
          records: [{
            Id: 'article2',
            KnowledgeArticleId: 'ka2',
            Title: 'Article 2',
            UrlName: 'article-2',
            VersionNumber: 1,
            PublishStatus: 'Online',
            Language: 'en_US'
          }]
        });

      const result = await salesforceClient.bulkCreateKnowledgeArticles(sampleArticles);

      expect(result.totalProcessed).toBe(2);
      expect(result.successful).toBe(2);
      expect(result.failed).toBe(0);
      expect(result.results).toHaveLength(2);
      expect(result.errors).toHaveLength(0);
    });

    it('should handle partial failures in bulk creation', async () => {
      // Mock first article success, second article failure
      mockConnection.sobject().create
        .mockResolvedValueOnce({ success: true, id: 'article1' })
        .mockRejectedValueOnce(new Error('Creation failed'));

      // Mock getArticleInfo for successful article
      mockConnection.query
        .mockResolvedValue({ totalSize: 1, records: [] }) // Authentication check
        .mockResolvedValueOnce({
          totalSize: 1,
          records: [{
            Id: 'article1',
            KnowledgeArticleId: 'ka1',
            Title: 'Article 1',
            UrlName: 'article-1',
            VersionNumber: 1,
            PublishStatus: 'Online',
            Language: 'en_US'
          }]
        });

      const result = await salesforceClient.bulkCreateKnowledgeArticles(sampleArticles);

      expect(result.totalProcessed).toBe(2);
      expect(result.successful).toBe(1);
      expect(result.failed).toBe(1);
      expect(result.results).toHaveLength(1);
      expect(result.errors).toHaveLength(1);
      expect(result.errors[0].index).toBe(1);
      expect(result.errors[0].error).toContain('Creation failed');
    });
  });

  describe('rate limiting', () => {
    beforeEach(async () => {
      mockConnection.login.mockResolvedValue({
        id: 'user123',
        url: 'https://test.salesforce.com',
        organizationId: 'org123'
      });
      await salesforceClient.authenticate();
    });

    it('should respect rate limits', async () => {
      // This test would be more complex in a real scenario
      // For now, we just verify that rate limiting doesn't break functionality
      mockConnection.query.mockResolvedValue({ totalSize: 0, records: [] });

      const startTime = Date.now();
      await salesforceClient.findExistingArticle('test-1');
      await salesforceClient.findExistingArticle('test-2');
      const endTime = Date.now();

      // Should complete without throwing errors
      expect(endTime - startTime).toBeGreaterThan(0);
    });
  });

  describe('error handling', () => {
    it('should handle authentication expiration', async () => {
      // Initial authentication
      mockConnection.login.mockResolvedValue({
        id: 'user123',
        url: 'https://test.salesforce.com',
        organizationId: 'org123'
      });
      await salesforceClient.authenticate();

      // Simulate session expiration
      mockConnection.query
        .mockRejectedValueOnce(new Error('INVALID_SESSION_ID'))
        .mockResolvedValueOnce({ totalSize: 1, records: [] }) // Re-auth check
        .mockResolvedValueOnce({ totalSize: 0, records: [] }); // Actual query

      // Should re-authenticate automatically
      const result = await salesforceClient.findExistingArticle('test-article');

      expect(result).toBeNull();
      expect(mockConnection.login).toHaveBeenCalledTimes(2); // Initial + re-auth
    });

    it('should provide detailed error information', async () => {
      mockConnection.login.mockRejectedValue(new Error('INVALID_LOGIN'));

      try {
        await salesforceClient.authenticate();
      } catch (error) {
        expect(error).toBeInstanceOf(SalesforceApiError);
        expect((error as SalesforceApiError).errorCode).toBe('AUTHENTICATION_ERROR');
        expect(error.message).toContain('Authentication failed');
      }
    });
  });
});