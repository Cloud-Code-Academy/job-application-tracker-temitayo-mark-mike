# API Reference - Enterprise Job Application Tracker

Complete API reference for all Apex services, Lightning Web Components, REST endpoints, and integration points.

## Table of Contents
1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Core Services](#core-services)
4. [Data Models](#data-models)
5. [Integration Points](#integration-points)
6. [Error Handling](#error-handling)
7. [Rate Limits](#rate-limits)
8. [Code Examples](#code-examples)

## Overview

The Job Application Tracker platform provides a comprehensive API for programmatic access to job application data, interview feedback, analytics, and management functions. This API is designed for integration with external systems, custom applications, and automated workflows.

### API Version
- **Current Version**: 1.0
- **Salesforce API Version**: 62.0
- **Base URL**: `https://your-instance.salesforce.com/services/apexrest/`

### Supported Formats
- **Request**: JSON
- **Response**: JSON
- **Authentication**: OAuth 2.0, Session ID

## Authentication

### OAuth 2.0 Flow
```http
POST /services/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=password&
client_id=YOUR_CLIENT_ID&
client_secret=YOUR_CLIENT_SECRET&
username=YOUR_USERNAME&
password=YOUR_PASSWORD_AND_SECURITY_TOKEN
```

### Session-Based Authentication
```apex
// Get session ID for API calls
String sessionId = UserInfo.getSessionId();
```

## Core Services

### InterviewFeedbackService

#### createFeedback
Creates a new interview feedback record with validation and defaults.

**Endpoint**: `POST /InterviewFeedback/create`

**Parameters**:
```json
{
  "jobApplicationId": "a03XXXXXXXXXXXXXXX",
  "interviewType": "Technical",
  "feedbackData": {
    "interviewRound": "Round 1",
    "interviewDate": "2024-01-15T14:30:00Z",
    "durationMinutes": 60,
    "interviewerName": "John Smith",
    "interviewerEmail": "john.smith@company.com",
    "overallRating": 4.0,
    "technicalRating": 4.5,
    "communicationRating": 3.5,
    "culturalFitRating": 4.0,
    "detailedFeedback": "Strong technical skills demonstrated...",
    "strengths": "Excellent problem-solving approach",
    "areasForImprovement": "Could improve communication clarity",
    "recommendation": "Hire"
  }
}
```

**Response**:
```json
{
  "success": true,
  "feedbackId": "a04XXXXXXXXXXXXXXX",
  "message": "Interview feedback created successfully",
  "competencyRatings": [
    {
      "competencyName": "Technical Skills",
      "rating": 4.5,
      "weight": 1.0
    }
  ]
}
```

**Apex Usage**:
```apex
Interview_Feedback__c feedback = InterviewFeedbackService.createFeedback(
    jobApplicationId,
    'Technical',
    new Map<String, Object>{
        'interviewRound' => 'Round 1',
        'overallRating' => 4.0,
        'technicalRating' => 4.5
    }
);
```

#### analyzeFeedback
Analyzes feedback for a job application and returns insights.

**Endpoint**: `GET /InterviewFeedback/analyze/{jobApplicationId}`

**Response**:
```json
{
  "success": true,
  "analysis": {
    "averageRating": 4.2,
    "totalInterviews": 3,
    "strengthAreas": ["Technical Skills", "Problem Solving"],
    "improvementAreas": ["Communication", "Cultural Fit"],
    "trendDirection": "Improving",
    "successProbability": 0.85,
    "recommendations": [
      "Focus on improving communication skills",
      "Practice behavioral interview questions"
    ]
  }
}
```

**Apex Usage**:
```apex
InterviewFeedbackService.FeedbackAnalysis analysis = 
    InterviewFeedbackService.analyzeFeedback(jobApplicationId);
```

#### generateRecommendations
Generates improvement recommendations based on feedback patterns.

**Endpoint**: `POST /InterviewFeedback/recommendations`

**Parameters**:
```json
{
  "feedbackIds": ["a04XXXXXXXXXXXXXXX", "a04YYYYYYYYYYYYYYY"]
}
```

**Response**:
```json
{
  "success": true,
  "recommendations": [
    {
      "category": "Technical Skills",
      "priority": "High",
      "recommendation": "Practice system design problems",
      "resources": [
        "https://example.com/system-design-course",
        "Designing Data-Intensive Applications book"
      ]
    }
  ]
}
```

### FeedbackAnalyticsService

#### calculateTrends
Calculates performance trends over a specified time period.

**Endpoint**: `GET /InterviewFeedback/trends/{jobApplicationId}?days={daysPeriod}`

**Parameters**:
- `jobApplicationId` (required): Job Application ID
- `days` (optional): Number of days to analyze (default: 90)

**Response**:
```json
{
  "success": true,
  "trends": [
    {
      "competency": "Technical Skills",
      "trendDirection": "Improving",
      "changeRate": 0.15,
      "significance": 0.95,
      "dataPoints": [
        {
          "date": "2024-01-01",
          "rating": 3.5
        },
        {
          "date": "2024-01-15",
          "rating": 4.0
        }
      ]
    }
  ]
}
```

**Apex Usage**:
```apex
List<FeedbackAnalyticsService.PerformanceTrend> trends = 
    FeedbackAnalyticsService.calculateTrends(jobApplicationId, 30);
```

#### analyzeCompetencies
Analyzes competency performance across all feedback records.

**Endpoint**: `POST /InterviewFeedback/competencies/analyze`

**Parameters**:
```json
{
  "feedbackIds": ["a04XXXXXXXXXXXXXXX", "a04YYYYYYYYYYYYYYY"],
  "includeComparisons": true
}
```

**Response**:
```json
{
  "success": true,
  "competencyAnalysis": {
    "strengths": [
      {
        "competency": "Technical Skills",
        "averageRating": 4.5,
        "percentile": 85,
        "consistency": 0.92
      }
    ],
    "improvementAreas": [
      {
        "competency": "Communication",
        "averageRating": 3.2,
        "percentile": 45,
        "gapFromTarget": 1.3
      }
    ],
    "benchmarks": {
      "industryAverage": 3.8,
      "peerAverage": 3.9,
      "topPerformerAverage": 4.6
    }
  }
}
```

#### generateDashboardData
Generates comprehensive dashboard data for visualization.

**Endpoint**: `GET /InterviewFeedback/dashboard/{userId}`

**Response**:
```json
{
  "success": true,
  "dashboardData": {
    "overview": {
      "totalInterviews": 15,
      "successRate": 0.73,
      "averageRating": 4.1,
      "trendDirection": "Stable"
    },
    "competencyRadar": {
      "labels": ["Technical", "Communication", "Problem Solving", "Cultural Fit"],
      "userScores": [4.5, 3.2, 4.1, 3.8],
      "benchmarkScores": [4.0, 3.8, 3.9, 4.2]
    },
    "performanceTrends": {
      "dates": ["2024-01-01", "2024-01-15", "2024-02-01"],
      "overallRatings": [3.8, 4.0, 4.2],
      "technicalRatings": [4.0, 4.2, 4.5]
    },
    "recentFeedback": [
      {
        "id": "a04XXXXXXXXXXXXXXX",
        "company": "Tech Corp",
        "date": "2024-02-01",
        "overallRating": 4.2,
        "recommendation": "Hire"
      }
    ]
  }
}
```

### FeedbackSharingService

#### createShareLink
Creates a secure sharing link for feedback collaboration.

**Endpoint**: `POST /InterviewFeedback/share`

**Parameters**:
```json
{
  "feedbackId": "a04XXXXXXXXXXXXXXX",
  "recipientEmail": "mentor@example.com",
  "accessLevel": "Comment",
  "expirationDays": 30,
  "dataMasking": true
}
```

**Response**:
```json
{
  "success": true,
  "shareId": "a05XXXXXXXXXXXXXXX",
  "shareToken": "abc123def456ghi789",
  "shareUrl": "https://your-instance.salesforce.com/feedback/share/abc123def456ghi789",
  "expirationDate": "2024-03-01T00:00:00Z"
}
```

**Apex Usage**:
```apex
String shareLink = FeedbackSharingService.createShareLink(
    feedbackId,
    'mentor@example.com',
    'Comment'
);
```

#### validateShareAccess
Validates access to shared feedback using a share token.

**Endpoint**: `GET /InterviewFeedback/share/validate/{shareToken}`

**Response**:
```json
{
  "success": true,
  "isValid": true,
  "accessLevel": "Comment",
  "expirationDate": "2024-03-01T00:00:00Z",
  "feedbackData": {
    "id": "a04XXXXXXXXXXXXXXX",
    "overallRating": 4.0,
    "detailedFeedback": "Strong performance in technical areas..."
  }
}
```

#### addMentorComment
Adds a mentor comment to shared feedback.

**Endpoint**: `POST /InterviewFeedback/share/comment`

**Parameters**:
```json
{
  "shareToken": "abc123def456ghi789",
  "comment": "Great technical skills! Consider working on presentation skills for executive interviews.",
  "commentType": "Suggestion",
  "isPrivate": false
}
```

**Response**:
```json
{
  "success": true,
  "commentId": "a06XXXXXXXXXXXXXXX",
  "timestamp": "2024-02-15T10:30:00Z"
}
```

### FeedbackTemplateService

#### getTemplatesByType
Retrieves feedback templates for a specific interview type.

**Endpoint**: `GET /InterviewFeedback/templates?type={interviewType}`

**Response**:
```json
{
  "success": true,
  "templates": [
    {
      "id": "a07XXXXXXXXXXXXXXX",
      "name": "Technical Interview - Software Engineer",
      "interviewType": "Technical",
      "competencyAreas": ["Coding", "System Design", "Problem Solving"],
      "ratingScale": "1-5",
      "templateJson": {
        "sections": [
          {
            "name": "Technical Assessment",
            "fields": [
              {
                "name": "coding_skills",
                "label": "Coding Skills",
                "type": "rating",
                "required": true
              }
            ]
          }
        ]
      }
    }
  ]
}
```

#### createCustomTemplate
Creates a new custom feedback template.

**Endpoint**: `POST /InterviewFeedback/templates`

**Parameters**:
```json
{
  "templateName": "Senior Developer Interview",
  "interviewType": "Technical",
  "competencyAreas": ["Architecture", "Leadership", "Mentoring"],
  "ratingScale": "1-5",
  "templateJson": {
    "sections": [
      {
        "name": "Leadership Assessment",
        "fields": [
          {
            "name": "team_leadership",
            "label": "Team Leadership",
            "type": "rating",
            "required": true
          }
        ]
      }
    ]
  }
}
```

## Data Models

### Interview_Feedback__c
```json
{
  "Id": "a04XXXXXXXXXXXXXXX",
  "Job_Application__c": "a03XXXXXXXXXXXXXXX",
  "Interview_Round__c": "Round 1",
  "Interviewer_Name__c": "John Smith",
  "Interviewer_Email__c": "john.smith@company.com",
  "Interview_Type__c": "Technical",
  "Interview_Date__c": "2024-01-15T14:30:00Z",
  "Duration_Minutes__c": 60,
  "Overall_Rating__c": 4.0,
  "Technical_Rating__c": 4.5,
  "Communication_Rating__c": 3.5,
  "Cultural_Fit_Rating__c": 4.0,
  "Detailed_Feedback__c": "Strong technical skills...",
  "Strengths__c": "Problem-solving approach",
  "Areas_For_Improvement__c": "Communication clarity",
  "Recommendation__c": "Hire",
  "Feedback_Source__c": "Self",
  "Feedback_Status__c": "Submitted",
  "Is_Confidential__c": false
}
```

### Competency_Rating__c
```json
{
  "Id": "a08XXXXXXXXXXXXXXX",
  "Interview_Feedback__c": "a04XXXXXXXXXXXXXXX",
  "Competency_Name__c": "Technical Skills",
  "Rating__c": 4.5,
  "Comments__c": "Excellent coding skills demonstrated",
  "Weight__c": 1.0
}
```

### Feedback_Share__c
```json
{
  "Id": "a05XXXXXXXXXXXXXXX",
  "Interview_Feedback__c": "a04XXXXXXXXXXXXXXX",
  "Shared_With_Email__c": "mentor@example.com",
  "Share_Token__c": "abc123def456ghi789",
  "Expiration_Date__c": "2024-03-01T00:00:00Z",
  "Access_Level__c": "Comment",
  "Is_Active__c": true,
  "Access_Count__c": 5
}
```

## Integration Points

### Job Application Tracker Integration

#### Automatic Status Updates
When interview feedback is created or updated, the system automatically:
- Updates Job Application status based on feedback outcomes
- Creates follow-up tasks for next steps
- Calculates interview success metrics

**Webhook Endpoint**: `POST /InterviewFeedback/webhook/status-update`

**Payload**:
```json
{
  "feedbackId": "a04XXXXXXXXXXXXXXX",
  "jobApplicationId": "a03XXXXXXXXXXXXXXX",
  "recommendation": "Hire",
  "overallRating": 4.5,
  "timestamp": "2024-02-15T10:30:00Z"
}
```

#### Task Creation Integration
```apex
// Automatically create follow-up tasks
public class InterviewFeedbackTriggerHandler {
    public static void createFollowUpTasks(List<Interview_Feedback__c> feedbacks) {
        List<Task> tasksToCreate = new List<Task>();
        
        for (Interview_Feedback__c feedback : feedbacks) {
            if (feedback.Recommendation__c == 'Hire' && feedback.Overall_Rating__c >= 4.0) {
                Task followUp = new Task();
                followUp.Subject = 'Follow up on positive interview feedback';
                followUp.WhatId = feedback.Job_Application__c;
                followUp.ActivityDate = Date.today().addDays(3);
                followUp.Priority = 'High';
                tasksToCreate.add(followUp);
            }
        }
        
        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }
}
```

### External System Integration

#### REST API Endpoints
All endpoints support standard REST operations:

- `GET /InterviewFeedback/{id}` - Retrieve specific feedback
- `POST /InterviewFeedback` - Create new feedback
- `PUT /InterviewFeedback/{id}` - Update existing feedback
- `DELETE /InterviewFeedback/{id}` - Delete feedback (soft delete)
- `GET /InterviewFeedback/search` - Search feedback records

#### Bulk Operations
For high-volume integrations:

**Bulk Create**: `POST /InterviewFeedback/bulk`
```json
{
  "feedbackRecords": [
    {
      "jobApplicationId": "a03XXXXXXXXXXXXXXX",
      "interviewType": "Technical",
      "feedbackData": {...}
    }
  ]
}
```

**Bulk Update**: `PUT /InterviewFeedback/bulk`
**Bulk Delete**: `DELETE /InterviewFeedback/bulk`

## Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Required field missing: Interview_Date__c",
    "details": {
      "field": "Interview_Date__c",
      "value": null,
      "requirement": "Date field is required for feedback creation"
    }
  },
  "timestamp": "2024-02-15T10:30:00Z",
  "requestId": "req_abc123def456"
}
```

### Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `VALIDATION_ERROR` | Input validation failed | 400 |
| `UNAUTHORIZED` | Authentication required | 401 |
| `FORBIDDEN` | Insufficient permissions | 403 |
| `NOT_FOUND` | Resource not found | 404 |
| `DUPLICATE_ERROR` | Duplicate record detected | 409 |
| `RATE_LIMIT_EXCEEDED` | Too many requests | 429 |
| `INTERNAL_ERROR` | Server error | 500 |
| `SERVICE_UNAVAILABLE` | Service temporarily unavailable | 503 |

### Exception Handling in Apex
```apex
try {
    Interview_Feedback__c feedback = InterviewFeedbackService.createFeedback(
        jobApplicationId, 
        interviewType, 
        feedbackData
    );
} catch (InterviewFeedbackService.ValidationException e) {
    // Handle validation errors
    System.debug('Validation error: ' + e.getMessage());
} catch (InterviewFeedbackService.SecurityException e) {
    // Handle security/permission errors
    System.debug('Security error: ' + e.getMessage());
} catch (Exception e) {
    // Handle unexpected errors
    System.debug('Unexpected error: ' + e.getMessage());
}
```

## Rate Limits

### API Rate Limits
- **Standard Users**: 1000 requests per hour
- **Premium Users**: 5000 requests per hour
- **System Integration**: 10000 requests per hour

### Governor Limits
When using Apex APIs directly:
- **SOQL Queries**: 100 per transaction
- **DML Statements**: 150 per transaction
- **CPU Time**: 10 seconds per transaction
- **Heap Size**: 6 MB per transaction

### Best Practices
- Implement exponential backoff for rate limit errors
- Use bulk operations for multiple records
- Cache frequently accessed data
- Implement proper error handling and retry logic

## Code Examples

### JavaScript/REST Integration
```javascript
// Create interview feedback via REST API
async function createInterviewFeedback(feedbackData) {
    const response = await fetch('/services/apexrest/InterviewFeedback/create', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${sessionId}`
        },
        body: JSON.stringify(feedbackData)
    });
    
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
}

// Usage
const feedbackData = {
    jobApplicationId: 'a03XXXXXXXXXXXXXXX',
    interviewType: 'Technical',
    feedbackData: {
        overallRating: 4.0,
        technicalRating: 4.5,
        detailedFeedback: 'Strong performance...'
    }
};

createInterviewFeedback(feedbackData)
    .then(result => console.log('Feedback created:', result))
    .catch(error => console.error('Error:', error));
```

### Python Integration
```python
import requests
import json

class InterviewFeedbackAPI:
    def __init__(self, instance_url, session_id):
        self.base_url = f"{instance_url}/services/apexrest"
        self.headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {session_id}'
        }
    
    def create_feedback(self, job_app_id, interview_type, feedback_data):
        url = f"{self.base_url}/InterviewFeedback/create"
        payload = {
            'jobApplicationId': job_app_id,
            'interviewType': interview_type,
            'feedbackData': feedback_data
        }
        
        response = requests.post(url, headers=self.headers, json=payload)
        response.raise_for_status()
        return response.json()
    
    def get_analytics(self, job_app_id):
        url = f"{self.base_url}/InterviewFeedback/analyze/{job_app_id}"
        response = requests.get(url, headers=self.headers)
        response.raise_for_status()
        return response.json()

# Usage
api = InterviewFeedbackAPI('https://your-instance.salesforce.com', 'your_session_id')

feedback_data = {
    'overallRating': 4.0,
    'technicalRating': 4.5,
    'detailedFeedback': 'Excellent technical skills demonstrated'
}

result = api.create_feedback('a03XXXXXXXXXXXXXXX', 'Technical', feedback_data)
print(f"Feedback created: {result['feedbackId']}")
```

### Apex Integration Examples
```apex
// Service layer integration
public class CustomInterviewProcessor {
    
    public static void processInterviewResults(List<InterviewResult> results) {
        List<Interview_Feedback__c> feedbackRecords = new List<Interview_Feedback__c>();
        
        for (InterviewResult result : results) {
            Map<String, Object> feedbackData = new Map<String, Object>{
                'interviewRound' => result.round,
                'overallRating' => result.rating,
                'detailedFeedback' => result.notes
            };
            
            Interview_Feedback__c feedback = InterviewFeedbackService.createFeedback(
                result.jobApplicationId,
                result.interviewType,
                feedbackData
            );
            
            feedbackRecords.add(feedback);
        }
        
        // Bulk process for analytics
        InterviewFeedbackService.processFeedbackBatch(feedbackRecords);
    }
    
    public static void generateWeeklyReports() {
        List<User> users = [SELECT Id FROM User WHERE IsActive = true];
        
        for (User user : users) {
            FeedbackAnalyticsService.DashboardData data = 
                FeedbackAnalyticsService.generateDashboardData(user.Id);
            
            if (data.overview.totalInterviews > 0) {
                // Send weekly performance report
                sendPerformanceReport(user.Id, data);
            }
        }
    }
}
```

---

*For additional API documentation, examples, or support, please contact the development team or refer to the Salesforce Developer Documentation.*