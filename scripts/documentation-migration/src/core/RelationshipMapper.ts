/**
 * Advanced relationship mapping system for cross-document references
 */

import { LinkMapper } from './LinkMapper';
import { FileMetadata } from '../types';
import { TextAnalyzer } from '../utils/TextAnalyzer';

export class RelationshipMapper {
  private linkMapper: LinkMapper;
  private documentGraph: DocumentGraph;
  private crossReferences: Map<string, CrossReference[]>;
  private relatedArticles: Map<string, RelatedArticle[]>;

  constructor(baseDirectory: string, linkMapper?: LinkMapper) {
    this.linkMapper = linkMapper || new LinkMapper(baseDirectory);
    this.documentGraph = new DocumentGraph();
    this.crossReferences = new Map();
    this.relatedArticles = new Map();
  }

  /**
   * Analyze relationships between documents
   */
  public analyzeRelationships(documents: DocumentInfo[]): RelationshipAnalysis {
    // Build document graph
    this.buildDocumentGraph(documents);
    
    // Analyze cross-references
    this.analyzeCrossReferences(documents);
    
    // Find related articles
    this.findRelatedArticles(documents);
    
    // Calculate relationship metrics
    const metrics = this.calculateRelationshipMetrics();
    
    return {
      documentGraph: this.documentGraph,
      crossReferences: Object.fromEntries(this.crossReferences),
      relatedArticles: Object.fromEntries(this.relatedArticles),
      metrics,
      recommendations: this.generateRelationshipRecommendations()
    };
  }

  /**
   * Generate related articles field content for a document
   */
  public generateRelatedArticlesContent(filePath: string): string | undefined {
    const related = this.relatedArticles.get(filePath);
    if (!related || related.length === 0) {
      return undefined;
    }

    // Sort by relevance score
    const sortedRelated = related
      .sort((a, b) => b.relevanceScore - a.relevanceScore)
      .slice(0, 10); // Limit to top 10

    // Generate HTML content
    const links = sortedRelated.map(article => {
      const url = this.linkMapper.resolveLink(article.filePath, filePath);
      if (url) {
        return `<a href="${url}" target="_blank">${article.title}</a>`;
      }
      return article.title;
    });

    return `<div class="related-articles">
      <h4>Related Articles</h4>
      <ul>
        ${links.map(link => `<li>${link}</li>`).join('\n        ')}
      </ul>
    </div>`;
  }

  /**
   * Find broken relationships
   */
  public findBrokenRelationships(): BrokenRelationship[] {
    const brokenRelationships: BrokenRelationship[] = [];

    for (const [sourceFile, references] of this.crossReferences.entries()) {
      for (const reference of references) {
        if (reference.type === 'internal_link' && !reference.resolved) {
          brokenRelationships.push({
            sourceFile,
            targetFile: reference.target,
            referenceType: reference.type,
            context: reference.context,
            lineNumber: reference.lineNumber,
            reason: 'Target file not found or not migrated'
          });
        }
      }
    }

    return brokenRelationships;
  }

  /**
   * Generate relationship report
   */
  public generateRelationshipReport(): RelationshipReport {
    const totalDocuments = this.documentGraph.getNodeCount();
    const totalRelationships = this.documentGraph.getEdgeCount();
    const brokenRelationships = this.findBrokenRelationships();
    
    return {
      summary: {
        totalDocuments,
        totalRelationships,
        brokenRelationships: brokenRelationships.length,
        averageRelationshipsPerDocument: totalDocuments > 0 ? totalRelationships / totalDocuments : 0
      },
      topConnectedDocuments: this.getTopConnectedDocuments(10),
      isolatedDocuments: this.getIsolatedDocuments(),
      brokenRelationships,
      relationshipTypes: this.getRelationshipTypeDistribution(),
      recommendations: this.generateRelationshipRecommendations()
    };
  }

  /**
   * Update relationships after migration
   */
  public updateRelationshipsPostMigration(migrationResults: any[]): void {
    // Update link mappings based on migration results
    for (const result of migrationResults) {
      if (result.success && result.articleId) {
        const knowledgeUrl = `/lightning/r/Knowledge__kav/${result.articleId}/view`;
        this.linkMapper.addMapping(result.filePath, knowledgeUrl);
      }
    }

    // Re-resolve cross-references
    this.resolveCrossReferences();
    
    // Update related articles with new URLs
    this.updateRelatedArticleUrls();
  }

  /**
   * Export relationship data
   */
  public exportRelationshipData(): RelationshipExport {
    return {
      documentGraph: this.documentGraph.export(),
      crossReferences: Object.fromEntries(this.crossReferences),
      relatedArticles: Object.fromEntries(this.relatedArticles),
      linkMappings: this.linkMapper.getAllMappings(),
      generatedAt: new Date().toISOString()
    };
  }

  // Private methods

  private buildDocumentGraph(documents: DocumentInfo[]): void {
    // Add all documents as nodes
    for (const doc of documents) {
      this.documentGraph.addNode(doc.filePath, {
        title: doc.metadata.title,
        category: doc.metadata.category,
        tags: doc.metadata.tags,
        wordCount: doc.metadata.wordCount
      });
    }

    // Add edges based on links and references
    for (const doc of documents) {
      const references = this.extractReferences(doc.content, doc.filePath);
      
      for (const ref of references) {
        if (ref.type === 'internal_link' && this.documentGraph.hasNode(ref.target)) {
          this.documentGraph.addEdge(doc.filePath, ref.target, {
            type: ref.type,
            weight: this.calculateLinkWeight(ref),
            context: ref.context
          });
        }
      }
    }
  }

  private analyzeCrossReferences(documents: DocumentInfo[]): void {
    for (const doc of documents) {
      const references = this.extractReferences(doc.content, doc.filePath);
      this.crossReferences.set(doc.filePath, references);
    }
  }

  private extractReferences(content: string, sourceFile: string): CrossReference[] {
    const references: CrossReference[] = [];
    const lines = content.split('\n');

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const lineNumber = i + 1;

      // Extract markdown links
      const linkMatches = line.matchAll(/\[([^\]]+)\]\(([^)]+)\)/g);
      for (const match of linkMatches) {
        const [fullMatch, text, href] = match;
        
        references.push({
          type: this.classifyReferenceType(href),
          target: href,
          text,
          context: this.extractContext(lines, i, 2),
          lineNumber,
          resolved: false
        });
      }

      // Extract direct file references
      const fileMatches = line.matchAll(/(?:see|refer to|check|read)\s+([a-zA-Z0-9_-]+\.md)/gi);
      for (const match of fileMatches) {
        const [fullMatch, filename] = match;
        
        references.push({
          type: 'file_reference',
          target: filename,
          text: fullMatch,
          context: this.extractContext(lines, i, 1),
          lineNumber,
          resolved: false
        });
      }

      // Extract section references
      const sectionMatches = line.matchAll(/#([a-zA-Z0-9_-]+)/g);
      for (const match of sectionMatches) {
        const [fullMatch, section] = match;
        
        references.push({
          type: 'section_reference',
          target: section,
          text: fullMatch,
          context: this.extractContext(lines, i, 1),
          lineNumber,
          resolved: false
        });
      }
    }

    return references;
  }

  private classifyReferenceType(href: string): ReferenceType {
    if (href.startsWith('http://') || href.startsWith('https://')) {
      return 'external_link';
    }
    if (href.startsWith('#')) {
      return 'anchor_link';
    }
    if (href.endsWith('.md')) {
      return 'internal_link';
    }
    if (href.includes('/')) {
      return 'file_path';
    }
    return 'unknown';
  }

  private extractContext(lines: string[], lineIndex: number, contextLines: number): string {
    const start = Math.max(0, lineIndex - contextLines);
    const end = Math.min(lines.length, lineIndex + contextLines + 1);
    return lines.slice(start, end).join('\n');
  }

  private findRelatedArticles(documents: DocumentInfo[]): void {
    for (const doc of documents) {
      const related = this.findRelatedForDocument(doc, documents);
      if (related.length > 0) {
        this.relatedArticles.set(doc.filePath, related);
      }
    }
  }

  private findRelatedForDocument(targetDoc: DocumentInfo, allDocuments: DocumentInfo[]): RelatedArticle[] {
    const related: RelatedArticle[] = [];

    for (const doc of allDocuments) {
      if (doc.filePath === targetDoc.filePath) continue;

      const relevanceScore = this.calculateRelevanceScore(targetDoc, doc);
      
      if (relevanceScore > 0.3) { // Threshold for relatedness
        related.push({
          filePath: doc.filePath,
          title: doc.metadata.title,
          relevanceScore,
          relationshipType: this.determineRelationshipType(targetDoc, doc),
          sharedTags: this.findSharedTags(targetDoc.metadata.tags, doc.metadata.tags),
          sharedKeywords: this.findSharedKeywords(targetDoc.content, doc.content)
        });
      }
    }

    return related.sort((a, b) => b.relevanceScore - a.relevanceScore);
  }

  private calculateRelevanceScore(doc1: DocumentInfo, doc2: DocumentInfo): number {
    let score = 0;

    // Category similarity
    if (doc1.metadata.category === doc2.metadata.category) {
      score += 0.3;
    }

    // Tag similarity
    const sharedTags = this.findSharedTags(doc1.metadata.tags, doc2.metadata.tags);
    score += (sharedTags.length / Math.max(doc1.metadata.tags.length, doc2.metadata.tags.length)) * 0.4;

    // Content similarity (simplified)
    const keywords1 = TextAnalyzer.extractKeywords(doc1.content, 20);
    const keywords2 = TextAnalyzer.extractKeywords(doc2.content, 20);
    const sharedKeywords = this.findSharedKeywords(
      keywords1.map(k => k.keyword).join(' '),
      keywords2.map(k => k.keyword).join(' ')
    );
    score += (sharedKeywords.length / Math.max(keywords1.length, keywords2.length)) * 0.3;

    return Math.min(score, 1.0);
  }

  private determineRelationshipType(doc1: DocumentInfo, doc2: DocumentInfo): RelationshipType {
    // Check for direct links
    if (this.documentGraph.hasEdge(doc1.filePath, doc2.filePath)) {
      return 'direct_link';
    }

    // Check for same category
    if (doc1.metadata.category === doc2.metadata.category) {
      return 'same_category';
    }

    // Check for shared tags
    const sharedTags = this.findSharedTags(doc1.metadata.tags, doc2.metadata.tags);
    if (sharedTags.length > 0) {
      return 'shared_tags';
    }

    return 'content_similarity';
  }

  private findSharedTags(tags1: string[], tags2: string[]): string[] {
    return tags1.filter(tag => tags2.includes(tag));
  }

  private findSharedKeywords(content1: string, content2: string): string[] {
    const keywords1 = TextAnalyzer.extractKeywords(content1, 10).map(k => k.keyword.toLowerCase());
    const keywords2 = TextAnalyzer.extractKeywords(content2, 10).map(k => k.keyword.toLowerCase());
    return keywords1.filter(keyword => keywords2.includes(keyword));
  }

  private calculateLinkWeight(reference: CrossReference): number {
    // Weight based on reference type and context
    let weight = 1.0;

    switch (reference.type) {
      case 'internal_link':
        weight = 1.0;
        break;
      case 'file_reference':
        weight = 0.8;
        break;
      case 'section_reference':
        weight = 0.6;
        break;
      default:
        weight = 0.5;
    }

    // Boost weight if reference appears in important contexts
    if (reference.context.includes('see also') || reference.context.includes('related')) {
      weight *= 1.2;
    }

    return weight;
  }

  private calculateRelationshipMetrics(): RelationshipMetrics {
    const totalNodes = this.documentGraph.getNodeCount();
    const totalEdges = this.documentGraph.getEdgeCount();
    
    return {
      totalDocuments: totalNodes,
      totalRelationships: totalEdges,
      averageConnections: totalNodes > 0 ? totalEdges / totalNodes : 0,
      maxConnections: this.documentGraph.getMaxDegree(),
      isolatedDocuments: this.documentGraph.getIsolatedNodes().length,
      stronglyConnectedComponents: this.documentGraph.getStronglyConnectedComponents().length
    };
  }

  private getTopConnectedDocuments(limit: number): ConnectedDocument[] {
    return this.documentGraph.getNodesByDegree()
      .slice(0, limit)
      .map(node => ({
        filePath: node.id,
        title: node.data.title,
        incomingLinks: this.documentGraph.getInDegree(node.id),
        outgoingLinks: this.documentGraph.getOutDegree(node.id),
        totalConnections: this.documentGraph.getDegree(node.id)
      }));
  }

  private getIsolatedDocuments(): string[] {
    return this.documentGraph.getIsolatedNodes();
  }

  private getRelationshipTypeDistribution(): Record<string, number> {
    const distribution: Record<string, number> = {};
    
    for (const references of this.crossReferences.values()) {
      for (const ref of references) {
        distribution[ref.type] = (distribution[ref.type] || 0) + 1;
      }
    }
    
    return distribution;
  }

  private generateRelationshipRecommendations(): string[] {
    const recommendations: string[] = [];
    const metrics = this.calculateRelationshipMetrics();
    
    if (metrics.isolatedDocuments > metrics.totalDocuments * 0.2) {
      recommendations.push('High number of isolated documents detected. Consider adding cross-references to improve navigation.');
    }
    
    if (metrics.averageConnections < 2) {
      recommendations.push('Low average connections per document. Adding related article suggestions could improve user experience.');
    }
    
    const brokenRelationships = this.findBrokenRelationships();
    if (brokenRelationships.length > 0) {
      recommendations.push(`${brokenRelationships.length} broken relationships found. Review and fix broken links before migration.`);
    }
    
    return recommendations;
  }

  private resolveCrossReferences(): void {
    for (const [sourceFile, references] of this.crossReferences.entries()) {
      for (const reference of references) {
        if (reference.type === 'internal_link') {
          const resolvedUrl = this.linkMapper.resolveLink(reference.target, sourceFile);
          reference.resolved = resolvedUrl !== null;
          if (resolvedUrl) {
            reference.resolvedUrl = resolvedUrl;
          }
        }
      }
    }
  }

  private updateRelatedArticleUrls(): void {
    for (const [sourceFile, relatedArticles] of this.relatedArticles.entries()) {
      for (const article of relatedArticles) {
        const resolvedUrl = this.linkMapper.resolveLink(article.filePath, sourceFile);
        if (resolvedUrl) {
          article.knowledgeUrl = resolvedUrl;
        }
      }
    }
  }
}

/**
 * Document graph for relationship analysis
 */
class DocumentGraph {
  private nodes: Map<string, GraphNode> = new Map();
  private edges: Map<string, GraphEdge[]> = new Map();

  addNode(id: string, data: any): void {
    this.nodes.set(id, { id, data });
    if (!this.edges.has(id)) {
      this.edges.set(id, []);
    }
  }

  addEdge(from: string, to: string, data: any): void {
    if (!this.edges.has(from)) {
      this.edges.set(from, []);
    }
    this.edges.get(from)!.push({ from, to, data });
  }

  hasNode(id: string): boolean {
    return this.nodes.has(id);
  }

  hasEdge(from: string, to: string): boolean {
    const edges = this.edges.get(from);
    return edges ? edges.some(edge => edge.to === to) : false;
  }

  getNodeCount(): number {
    return this.nodes.size;
  }

  getEdgeCount(): number {
    let count = 0;
    for (const edges of this.edges.values()) {
      count += edges.length;
    }
    return count;
  }

  getDegree(nodeId: string): number {
    return this.getInDegree(nodeId) + this.getOutDegree(nodeId);
  }

  getInDegree(nodeId: string): number {
    let count = 0;
    for (const edges of this.edges.values()) {
      count += edges.filter(edge => edge.to === nodeId).length;
    }
    return count;
  }

  getOutDegree(nodeId: string): number {
    const edges = this.edges.get(nodeId);
    return edges ? edges.length : 0;
  }

  getMaxDegree(): number {
    let max = 0;
    for (const nodeId of this.nodes.keys()) {
      max = Math.max(max, this.getDegree(nodeId));
    }
    return max;
  }

  getIsolatedNodes(): string[] {
    const isolated: string[] = [];
    for (const nodeId of this.nodes.keys()) {
      if (this.getDegree(nodeId) === 0) {
        isolated.push(nodeId);
      }
    }
    return isolated;
  }

  getNodesByDegree(): GraphNode[] {
    return Array.from(this.nodes.values())
      .sort((a, b) => this.getDegree(b.id) - this.getDegree(a.id));
  }

  getStronglyConnectedComponents(): string[][] {
    // Simplified implementation - in practice, would use Tarjan's algorithm
    return [];
  }

  export(): any {
    return {
      nodes: Array.from(this.nodes.values()),
      edges: Array.from(this.edges.entries()).flatMap(([from, edges]) => 
        edges.map(edge => ({ from, to: edge.to, data: edge.data }))
      )
    };
  }
}

// Type definitions

export interface DocumentInfo {
  filePath: string;
  content: string;
  metadata: FileMetadata;
}

export interface CrossReference {
  type: ReferenceType;
  target: string;
  text: string;
  context: string;
  lineNumber: number;
  resolved: boolean;
  resolvedUrl?: string;
}

export interface RelatedArticle {
  filePath: string;
  title: string;
  relevanceScore: number;
  relationshipType: RelationshipType;
  sharedTags: string[];
  sharedKeywords: string[];
  knowledgeUrl?: string;
}

export interface RelationshipAnalysis {
  documentGraph: DocumentGraph;
  crossReferences: Record<string, CrossReference[]>;
  relatedArticles: Record<string, RelatedArticle[]>;
  metrics: RelationshipMetrics;
  recommendations: string[];
}

export interface RelationshipMetrics {
  totalDocuments: number;
  totalRelationships: number;
  averageConnections: number;
  maxConnections: number;
  isolatedDocuments: number;
  stronglyConnectedComponents: number;
}

export interface BrokenRelationship {
  sourceFile: string;
  targetFile: string;
  referenceType: ReferenceType;
  context: string;
  lineNumber: number;
  reason: string;
}

export interface RelationshipReport {
  summary: {
    totalDocuments: number;
    totalRelationships: number;
    brokenRelationships: number;
    averageRelationshipsPerDocument: number;
  };
  topConnectedDocuments: ConnectedDocument[];
  isolatedDocuments: string[];
  brokenRelationships: BrokenRelationship[];
  relationshipTypes: Record<string, number>;
  recommendations: string[];
}

export interface ConnectedDocument {
  filePath: string;
  title: string;
  incomingLinks: number;
  outgoingLinks: number;
  totalConnections: number;
}

export interface RelationshipExport {
  documentGraph: any;
  crossReferences: Record<string, CrossReference[]>;
  relatedArticles: Record<string, RelatedArticle[]>;
  linkMappings: Record<string, string>;
  generatedAt: string;
}

interface GraphNode {
  id: string;
  data: any;
}

interface GraphEdge {
  from: string;
  to: string;
  data: any;
}

type ReferenceType = 'internal_link' | 'external_link' | 'anchor_link' | 'file_reference' | 'section_reference' | 'file_path' | 'unknown';
type RelationshipType = 'direct_link' | 'same_category' | 'shared_tags' | 'content_similarity';