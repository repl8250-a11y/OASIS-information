# User Service

The user-service centralizes user profiles, preferences, and non-sensitive personalization data. Authentication is delegated to auth-service — user-service stores profile attributes.

Responsibilities
- CRUD over user profiles
- Manage user preferences and notification settings
- Publish user.updated events

Architecture
- Python FastAPI
- Postgres for profile storage

API
- GET /api/v1/users/{id}
- POST /api/v1/users

Environment
- USER_PORT=8088
