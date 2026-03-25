---
title: API Reference
category: Reference
tags: [api, reference, endpoints, authentication]
difficulty: Intermediate
author: API Team
created: 2024-01-10
updated: 2024-01-25
---

# API Reference

Complete reference documentation for our REST API.

## Base URL

```
https://api.example.com/v1
```

## Authentication

All API requests require authentication using an API key:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://api.example.com/v1/endpoint
```

For more details, see [Authentication Guide](authentication.md).

## Endpoints

### Users

#### GET /users

Retrieve a list of users.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `limit` | integer | No | Number of users to return (default: 20) |
| `offset` | integer | No | Number of users to skip (default: 0) |
| `filter` | string | No | Filter users by name or email |

**Response:**

```json
{
  "users": [
    {
      "id": "user_123",
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "total": 150,
  "has_more": true
}
```

#### POST /users

Create a new user.

**Request Body:**

```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "role": "user"
}
```

**Response:**

```json
{
  "id": "user_456",
  "name": "Jane Smith",
  "email": "jane@example.com",
  "role": "user",
  "created_at": "2024-01-25T14:20:00Z"
}
```

### Data

#### GET /data

Retrieve data records.

**Query Parameters:**

- `type`: Filter by data type
- `date_from`: Start date (ISO 8601)
- `date_to`: End date (ISO 8601)

**Example:**

```bash
curl "https://api.example.com/v1/data?type=analytics&date_from=2024-01-01" \
     -H "Authorization: Bearer YOUR_API_KEY"
```

## Error Handling

The API uses standard HTTP status codes:

| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 429 | Rate Limited |
| 500 | Internal Server Error |

**Error Response Format:**

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "The request is invalid",
    "details": "Missing required parameter: name"
  }
}
```

## Rate Limits

- 1000 requests per hour for authenticated requests
- 100 requests per hour for unauthenticated requests

Rate limit headers are included in all responses:

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## SDKs and Libraries

Official SDKs are available for:

- [JavaScript/Node.js](sdk-javascript.md)
- [Python](sdk-python.md)
- [PHP](sdk-php.md)
- [Ruby](sdk-ruby.md)

## Changelog

See [API Changelog](api-changelog.md) for version history and breaking changes.

## Support

For API support:

- Check the [FAQ](api-faq.md)
- Visit [Stack Overflow](https://stackoverflow.com/questions/tagged/our-api)
- Contact [API Support](mailto:api-support@example.com)