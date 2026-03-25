/**
 * Salesforce API integration layer for Knowledge Base operations
 */

import jsforce from 'jsforce';
import { SalesforceConfig, KnowledgeArticleData } from '../types';

export class SalesforceClient {
  private connection: jsforce.Connection;
  private config: SalesforceConfig;
  private isAuthenticated: boolean = false;
  private rateLimitTracker: RateLimitTracker;

  constructor(config: SalesforceConfig) {
    this.config = config;
    this.connection = new jsforce.Connection({
      loginUrl: config.loginUrl,
      version: config.apiVersion
    });
    this.rateLimitTracker = new RateLimitTracker();
  }

  /**
   * Authenticate with Salesforce
   */
  public async authenticate(): Promise<AuthenticationResult> {
    try {
      const loginResult = await this.connection.login(
        this.config.username,
        this.config.password + this.config.securityToken
      );

      this.isAuthenticated = true;
      
      return {
        success: true,
        sessionId: loginResult.id,
        serverUrl: loginResult.url,
        organizationId: loginResult.organizationId,
        userInfo: {
          userId: loginResult.id,
          username: this.config.username,
          organizationId: loginResult.organizationId
        }
      };
    } catch (error) {
      this.isAuthenticated = false;
      throw new SalesforceApiError(`Authentication failed: ${error}`, 'AUTHENTICATION_ERROR');
    }
  }

  /**
   * Create a new Knowledge article
   */
  public async createKnowledgeArticle(articleData: KnowledgeArticleData): Promise<KnowledgeArticleResult> {
    await this.ensureAuthenticated();
    await this.rateLimitTracker.waitIfNeeded();

    try {
      // First, create the Knowledge article version
      const createResult = await this.connection.sobject('Documentation_Article__kav').create({
        Title: articleData.Title,
        UrlName: articleData.UrlName,
        Summary: articleData.Summary,
        Content__c: articleData.Content__c,
        Difficulty_Level__c: articleData.Difficulty_Level__c,
        Reading_Time__c: articleData.Reading_Time__c,
        Tags__c: articleData.Tags__c,
        Prerequisites__c: articleData.Prerequisites__c,
        Related_Articles__c: articleData.Related_Articles__c,
        Language: articleData.Language,
        IsVisibleInApp: articleData.IsVisibleInApp,
        IsVisibleInPkb: articleData.IsVisibleInPkb,
        IsVisibleInCsp: articleData.IsVisibleInCsp
      });

      if (!createResult.success) {
        throw new Error(`Failed to create article: ${createResult.errors?.join(', ')}`);
      }

      // Publish the article
      const publishResult = await this.publishKnowledgeArticle(createResult.id);

      this.rateLimitTracker.recordRequest();

      return {
        success: true,
        articleId: createResult.id,
        knowledgeArticleId: publishResult.knowledgeArticleId,
        urlName: articleData.UrlName,
        publishStatus: publishResult.publishStatus,
        versionNumber: publishResult.versionNumber
      };
    } catch (error) {
      throw new SalesforceApiError(`Failed to create Knowledge article: ${error}`, 'CREATE_ERROR');
    }
  }

  /**
   * Update an existing Knowledge article
   */
  public async updateKnowledgeArticle(articleId: string, articleData: Partial<KnowledgeArticleData>): Promise<KnowledgeArticleResult> {
    await this.ensureAuthenticated();
    await this.rateLimitTracker.waitIfNeeded();

    try {
      // Update the article version
      const updateResult = await this.connection.sobject('Documentation_Article__kav').update({
        Id: articleId,
        ...articleData
      });

      if (!updateResult.success) {
        throw new Error(`Failed to update article: ${updateResult.errors?.join(', ')}`);
      }

      // Re-publish if needed
      const publishResult = await this.publishKnowledgeArticle(articleId);

      this.rateLimitTracker.recordRequest();

      return {
        success: true,
        articleId: articleId,
        knowledgeArticleId: publishResult.knowledgeArticleId,
        urlName: articleData.UrlName,
        publishStatus: publishResult.publishStatus,
        versionNumber: publishResult.versionNumber
      };
    } catch (error) {
      throw new SalesforceApiError(`Failed to update Knowledge article: ${error}`, 'UPDATE_ERROR');
    }
  }

  /**
   * Find existing article by URL name
   */
  public async findExistingArticle(urlName: string): Promise<ExistingArticleResult | null> {
    await this.ensureAuthenticated();
    await this.rateLimitTracker.waitIfNeeded();

    try {
      const query = `
        SELECT Id, KnowledgeArticleId, Title, UrlName, VersionNumber, PublishStatus, Language
        FROM Documentation_Article__kav 
        WHERE UrlName = '${urlName}' 
        AND Language = 'en_US'
        ORDER BY VersionNumber DESC
        LIMIT 1
      `;

      const result = await this.connection.query(query);
      this.rateLimitTracker.recordRequest();

      if (result.totalSize > 0) {
        const record = result.records[0] as any;
        return {
          found: true,
          articleId: record.Id,
          knowledgeArticleId: record.KnowledgeArticleId,
          title: record.Title,
          urlName: record.UrlName,
          versionNumber: record.VersionNumber,
          publishStatus: record.PublishStatus,
          language: record.Language
        };
      }

      return null;
    } catch (error) {
      throw new SalesforceApiError(`Failed to find existing article: ${error}`, 'QUERY_ERROR');
    }
  }

  /**
   * Delete a Knowledge article
   */
  public async deleteKnowledgeArticle(articleId: string): Promise<DeleteResult> {
    await this.ensureAuthenticated();
    await this.rateLimitTracker.waitIfNeeded();

    try {
      const deleteResult = await this.connection.sobject('Documentation_Article__kav').delete(articleId);
      this.rateLimitTracker.recordRequest();

      return {
        success: deleteResult.success,
        articleId: articleId,
        errors: deleteResult.errors
      };
    } catch (error) {
      throw new SalesforceApiError(`Failed to delete Knowledge article: ${error}`, 'DELETE_ERROR');
    }
  }

  /**
   * Publish a Knowledge article
   */
  public async publishKnowledgeArticle(articleId: string): Promise<PublishResult> {
    await this.ensureAuthenticated();
    await this.rateLimitTracker.waitIfNeeded();

    try {
      // Check if article is already published
      const articleInfo = await this.getArticleInfo(articleId);
      if (articleInfo.publishStatus === 'Online') {
        return {
          success: true,
          knowledgeArticleId: articleInfo.knowledgeArticleId,
          publishStatus: 'Online',
          versionNumber: articleInfo.versionNumber
        };
      }

      // Publish the article using the KbManagement API
      const publishResult = await this.connection.request({
        method: 'POST',
        url: `/services/data/v${this.config.apiVersion}/knowledgeManagement/articleVersions/masterVersions`,
        body: JSON.stringify({
          articleId: articleInfo.knowledgeArticleId,
          publishStatus: 'Online'
        }),
        headers: {
          'Content-Type': 'application/json'
        }
      });

      this.rateLimitTracker.recordRequest();

      return {
        success: true,
        knowledgeArticleId: articleInfo.knowledgeArticleId,
        publishStatus: 'Online',
        versionNumber: publishResult.versionNumber || articleInfo.versionNumber
      };
    } catch (error) {
      // If publishing fails, the article still exists as draft
      console.warn(`Failed to publish article ${articleId}: ${error}`);
      const articleInfo = await this.getArticleInfo(articleId);
      
      return {
        success: false,
        knowledgeArticleId: articleInfo.knowledgeArticleId,
        publishStatus: 'Draft',
        versionNumber: articleInfo.versionNumber,
        error: error instanceof Error ? error.message : String(error)
      };
    }
  }

  /**
   * Get article information
   */
  public async getArticleInfo(articleId: string): Promise<ArticleInfo> {
    await this.ensureAuthenticated();
    await this.rateLimitTracker.waitIfNeeded();

    try {
      const query = `
        SELECT Id, KnowledgeArticleId, Title, UrlName, VersionNumber, PublishStatus, Language
        FROM Documentation_Article__kav 
        WHERE Id = '${articleId}'
        LIMIT 1
      `;

      const result = await this.connection.query(query);
      this.rateLimitTracker.recordRequest();

      if (result.totalSize === 0) {
        throw new Error(`Article not found: ${articleId}`);
      }

      const record = result.records[0] as any;
      return {
        articleId: record.Id,
        knowledgeArticleId: record.KnowledgeArticleId,
        title: record.Title,
        urlName: record.UrlName,
        versionNumber: record.VersionNumber,
        publishStatus: record.PublishStatus,
        language: record.Language
      };
    } catch (error) {
      throw new SalesforceApiError(`Failed to get article info: ${error}`, 'QUERY_ERROR');
    }
  }

  /**
   * Bulk create Knowledge articles
   */
  public async bulkCreateKnowledgeArticles(articles: KnowledgeArticleData[]): Promise<BulkOperationResult> {
    await this.ensureAuthenticated();

    const results: KnowledgeArticleResult[] = [];
    const errors: BulkError[] = [];
    const batchSize = 10; // Conservative batch size to avoid limits

    for (let i = 0; i < articles.length; i += batchSize) {
      const batch = articles.slice(i, i + batchSize);
      
      for (const article of batch) {
        try {
          const result = await this.createKnowledgeArticle(article);
          results.push(result);
        } catch (error) {
          errors.push({
            index: i + batch.indexOf(article),
            article: article,
            error: error instanceof Error ? error.message : String(error)
          });
        }

        // Add delay between requests to avoid rate limits
        await this.delay(100);
      }

      // Longer delay between batches
      if (i + batchSize < articles.length) {
        await this.delay(1000);
      }
    }

    return {
      totalProcessed: articles.length,
      successful: results.length,
      failed: errors.length,
      results: results,
      errors: errors
    };
  }

  /**
   * Test Salesforce connection
   */
  public async testConnection(): Promise<ConnectionTestResult> {
    try {
      await this.authenticate();
      
      // Test basic query
      const testQuery = 'SELECT Id FROM Organization LIMIT 1';
      await this.connection.query(testQuery);

      // Test Knowledge article access
      const knowledgeQuery = 'SELECT Id FROM Documentation_Article__kav LIMIT 1';
      const knowledgeResult = await this.connection.query(knowledgeQuery);

      return {
        success: true,
        authenticated: true,
        knowledgeAccessible: true,
        organizationId: this.connection.userInfo?.organizationId,
        userId: this.connection.userInfo?.id,
        apiVersion: this.config.apiVersion
      };
    } catch (error) {
      return {
        success: false,
        authenticated: this.isAuthenticated,
        knowledgeAccessible: false,
        error: error instanceof Error ? error.message : String(error)
      };
    }
  }

  /**
   * Get API usage statistics
   */
  public async getApiUsage(): Promise<ApiUsageStats> {
    await this.ensureAuthenticated();

    try {
      const limits = await this.connection.limits();
      
      return {
        dailyApiRequests: {
          used: limits.DailyApiRequests?.Remaining ? 
            limits.DailyApiRequests.Max - limits.DailyApiRequests.Remaining : 0,
          max: limits.DailyApiRequests?.Max || 0,
          remaining: limits.DailyApiRequests?.Remaining || 0
        },
        hourlyTimeBasedWorkflow: {
          used: limits.HourlyTimeBasedWorkflow?.Remaining ?
            limits.HourlyTimeBasedWorkflow.Max - limits.HourlyTimeBasedWorkflow.Remaining : 0,
          max: limits.HourlyTimeBasedWorkflow?.Max || 0,
          remaining: limits.HourlyTimeBasedWorkflow?.Remaining || 0
        },
        rateLimitInfo: this.rateLimitTracker.getStats()
      };
    } catch (error) {
      throw new SalesforceApiError(`Failed to get API usage: ${error}`, 'LIMITS_ERROR');
    }
  }

  /**
   * Ensure authentication is valid
   */
  private async ensureAuthenticated(): Promise<void> {
    if (!this.isAuthenticated) {
      await this.authenticate();
    }

    // Test if session is still valid
    try {
      await this.connection.query('SELECT Id FROM Organization LIMIT 1');
    } catch (error) {
      // Session expired, re-authenticate
      this.isAuthenticated = false;
      await this.authenticate();
    }
  }

  /**
   * Utility method to add delays
   */
  private async delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * Rate limit tracker to manage API usage
 */
class RateLimitTracker {
  private requestTimes: number[] = [];
  private readonly maxRequestsPerSecond = 20; // Conservative limit
  private readonly windowMs = 1000;

  public async waitIfNeeded(): Promise<void> {
    const now = Date.now();
    
    // Remove old requests outside the window
    this.requestTimes = this.requestTimes.filter(time => now - time < this.windowMs);
    
    // If we're at the limit, wait
    if (this.requestTimes.length >= this.maxRequestsPerSecond) {
      const oldestRequest = Math.min(...this.requestTimes);
      const waitTime = this.windowMs - (now - oldestRequest) + 100; // Add 100ms buffer
      
      if (waitTime > 0) {
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    }
  }

  public recordRequest(): void {
    this.requestTimes.push(Date.now());
  }

  public getStats(): RateLimitStats {
    const now = Date.now();
    const recentRequests = this.requestTimes.filter(time => now - time < this.windowMs);
    
    return {
      requestsInLastSecond: recentRequests.length,
      maxRequestsPerSecond: this.maxRequestsPerSecond,
      utilizationPercentage: (recentRequests.length / this.maxRequestsPerSecond) * 100
    };
  }
}

/**
 * Custom error class for Salesforce API errors
 */
export class SalesforceApiError extends Error {
  public readonly errorCode: string;
  public readonly salesforceErrors?: any[];

  constructor(message: string, errorCode: string, salesforceErrors?: any[]) {
    super(message);
    this.name = 'SalesforceApiError';
    this.errorCode = errorCode;
    this.salesforceErrors = salesforceErrors;
  }
}

// Type definitions

export interface AuthenticationResult {
  success: boolean;
  sessionId?: string;
  serverUrl?: string;
  organizationId?: string;
  userInfo?: {
    userId: string;
    username: string;
    organizationId: string;
  };
  error?: string;
}

export interface KnowledgeArticleResult {
  success: boolean;
  articleId: string;
  knowledgeArticleId?: string;
  urlName?: string;
  publishStatus?: string;
  versionNumber?: number;
  error?: string;
}

export interface ExistingArticleResult {
  found: boolean;
  articleId?: string;
  knowledgeArticleId?: string;
  title?: string;
  urlName?: string;
  versionNumber?: number;
  publishStatus?: string;
  language?: string;
}

export interface DeleteResult {
  success: boolean;
  articleId: string;
  errors?: any[];
}

export interface PublishResult {
  success: boolean;
  knowledgeArticleId: string;
  publishStatus: string;
  versionNumber?: number;
  error?: string;
}

export interface ArticleInfo {
  articleId: string;
  knowledgeArticleId: string;
  title: string;
  urlName: string;
  versionNumber: number;
  publishStatus: string;
  language: string;
}

export interface BulkOperationResult {
  totalProcessed: number;
  successful: number;
  failed: number;
  results: KnowledgeArticleResult[];
  errors: BulkError[];
}

export interface BulkError {
  index: number;
  article: KnowledgeArticleData;
  error: string;
}

export interface ConnectionTestResult {
  success: boolean;
  authenticated: boolean;
  knowledgeAccessible: boolean;
  organizationId?: string;
  userId?: string;
  apiVersion?: string;
  error?: string;
}

export interface ApiUsageStats {
  dailyApiRequests: {
    used: number;
    max: number;
    remaining: number;
  };
  hourlyTimeBasedWorkflow: {
    used: number;
    max: number;
    remaining: number;
  };
  rateLimitInfo: RateLimitStats;
}

export interface RateLimitStats {
  requestsInLastSecond: number;
  maxRequestsPerSecond: number;
  utilizationPercentage: number;
}