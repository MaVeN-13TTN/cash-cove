# Budget Tracker API Documentation

## Overview
This document provides comprehensive documentation for the Budget Tracker API endpoints and their corresponding frontend service calls.

## API Endpoints

### Authentication
- `POST /api/auth/login/`
- `POST /api/auth/register/`
- `POST /api/auth/refresh-token/`
- `POST /api/auth/logout/`

### Budget Management
- `GET /api/budgets/`
- `POST /api/budgets/`
- `PUT /api/budgets/{id}/`
- `DELETE /api/budgets/{id}/`
- `GET /api/budgets/{id}/analytics/`

### Expense Tracking
- `GET /api/expenses/`
- `POST /api/expenses/`
- `PUT /api/expenses/{id}/`
- `DELETE /api/expenses/{id}/`
- `GET /api/expenses/analytics/`

### Notifications
- `GET /api/notifications/`
- `PUT /api/notifications/{id}/read/`
- `POST /api/notifications/settings/`

### WebSocket Events
- `budget.updated`
- `transaction.created`
- `notification.created`

## Frontend-Backend Integration
- All API calls are handled through the ApiClient service
- WebSocket connections managed by WebSocketService
- Real-time updates implemented using Phoenix channels
- Error handling standardized across all endpoints

## Data Validation
Shared validation schemas are implemented for:
- Budget creation/updates
- Transaction recording
- User settings
- Notification preferences

## Error Codes
Standardized error codes and messages:
- 1000: Authentication Error
- 2000: Validation Error
- 3000: Resource Not Found
- 4000: Permission Denied
- 5000: Server Error
