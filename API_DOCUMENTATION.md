# Premium Podcast API Documentation

This document outlines the API endpoints for the Premium Podcast feature.

## Base URL

All API endpoints are relative to your Supabase project URL:

```
https://[YOUR_PROJECT_REF].supabase.co
```

## Authentication

All requests must include an Authorization header with a valid JWT token:

```
Authorization: Bearer [JWT_TOKEN]
```

## Endpoints

### Generate Premium Podcast

Creates a new premium podcast and initiates the generation process.

**URL**: `/functions/v1/generate-premium-podcast`

**Method**: `POST`

**Request Body**:

```json
{
  "topic": "Faith and Prayer",
  "duration": 15,
  "voices": ["alloy", "echo"],
  "initialRequest": true
}
```

**Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| topic | string | Yes | The topic for the podcast |
| duration | number | Yes | Duration in minutes (5, 10, 15, 30, 45, or 60) |
| voices | array | Yes | Array of voice IDs (minimum 2) |
| initialRequest | boolean | Yes | Set to true for initial request |

**Response**:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Faith and Prayer Discussion",
  "description": "A conversation about Faith and Prayer",
  "topic": "Faith and Prayer",
  "audio_url": null,
  "status": "generating",
  "duration": 15,
  "character_count": 11250,
  "created_at": "2025-03-05T12:00:00Z",
  "updated_at": "2025-03-05T12:00:00Z"
}
```

**Status Codes**:

| Status Code | Description |
|-------------|-------------|
| 201 | Podcast creation successful |
| 400 | Invalid request parameters |
| 401 | Unauthorized |
| 403 | Insufficient character limit |
| 500 | Server error |

### Fetch Premium Podcasts

Retrieves all premium podcasts for the authenticated user.

**URL**: `/rest/v1/premium_podcasts`

**Method**: `GET`

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| select | string | No | Comma-separated list of fields to return |
| order | string | No | Field to order by (e.g., created_at.desc) |
| limit | number | No | Maximum number of records to return |
| offset | number | No | Number of records to skip |

**Example Request**:

```
GET /rest/v1/premium_podcasts?select=*&order=created_at.desc&limit=10
```

**Response**:

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Faith and Prayer Discussion",
    "description": "A conversation about Faith and Prayer",
    "topic": "Faith and Prayer",
    "audio_url": "https://[YOUR_PROJECT_REF].supabase.co/storage/v1/object/public/premium-podcasts/550e8400-e29b-41d4-a716-446655440000.mp3",
    "status": "ready",
    "duration": 15,
    "character_count": 11250,
    "created_at": "2025-03-05T12:00:00Z",
    "updated_at": "2025-03-05T12:00:05Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Understanding Scripture Discussion",
    "description": "A conversation about Understanding Scripture",
    "topic": "Understanding Scripture",
    "audio_url": null,
    "status": "generating",
    "duration": 30,
    "character_count": 22500,
    "created_at": "2025-03-04T15:30:00Z",
    "updated_at": "2025-03-04T15:30:00Z"
  }
]
```

**Status Codes**:

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 401 | Unauthorized |
| 500 | Server error |

### Get Premium Podcast by ID

Retrieves a specific premium podcast by ID.

**URL**: `/rest/v1/premium_podcasts`

**Method**: `GET`

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | The UUID of the podcast |
| select | string | No | Comma-separated list of fields to return |

**Example Request**:

```
GET /rest/v1/premium_podcasts?id=eq.550e8400-e29b-41d4-a716-446655440000&select=*
```

**Response**:

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Faith and Prayer Discussion",
    "description": "A conversation about Faith and Prayer",
    "topic": "Faith and Prayer",
    "audio_url": "https://[YOUR_PROJECT_REF].supabase.co/storage/v1/object/public/premium-podcasts/550e8400-e29b-41d4-a716-446655440000.mp3",
    "status": "ready",
    "duration": 15,
    "character_count": 11250,
    "created_at": "2025-03-05T12:00:00Z",
    "updated_at": "2025-03-05T12:00:05Z"
  }
]
```

**Status Codes**:

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 401 | Unauthorized |
| 404 | Podcast not found |
| 500 | Server error |

## Podcast Status Values

The `status` field in the podcast object can have the following values:

| Status | Description |
|--------|-------------|
| generating | Initial state, podcast is being generated |
| generating_script | Script is being generated |
| generating_audio | Audio is being generated from the script |
| uploading | Audio is being uploaded to storage |
| ready | Podcast is ready for playback |
| failed | Generation process failed |

## Error Responses

Error responses will have the following format:

```json
{
  "error": {
    "message": "Error message description",
    "code": "ERROR_CODE"
  }
}
```

Common error codes:

| Error Code | Description |
|------------|-------------|
| INVALID_PARAMS | Invalid request parameters |
| INSUFFICIENT_CHARACTERS | User has insufficient character limit |
| UNAUTHORIZED | User is not authenticated |
| SERVER_ERROR | Internal server error |

## Rate Limits

- 10 requests per minute for the generate endpoint
- 60 requests per minute for the fetch endpoints

## Character Usage

Each premium user is limited to 45,000 characters per month, which equates to approximately 60 minutes of audio content. The character count is calculated based on the podcast duration:

- 5 minutes: 3,750 characters
- 10 minutes: 7,500 characters
- 15 minutes: 11,250 characters
- 30 minutes: 22,500 characters
- 45 minutes: 33,750 characters
- 60 minutes: 45,000 characters

The character count is deducted from the user's monthly limit when a podcast is successfully generated. 