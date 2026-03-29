# FastAPI Backend

This backend provides a lightweight local-first API layer for Serenity. It is designed to run independently of any uncommitted AWS Bedrock work and keeps the architecture simple enough for hackathon iteration while staying easy to extend later.

## Features

- Health check endpoint
- Anonymous user/profile endpoints
- Mood tracking APIs
- Journal APIs
- Chat session and message persistence
- Notification placeholder APIs
- WebSocket realtime chat per session
- SQLite by default, with `DATABASE_URL` ready for PostgreSQL later
- AI placeholder endpoints for future Bedrock integration

## Folder layout

```text
backend/
├── app/
│   ├── api/
│   ├── core/
│   ├── db/
│   ├── models/
│   ├── schemas/
│   ├── services/
│   ├── websocket/
│   └── main.py
├── .env.example
├── README.md
└── requirements.txt
```

## Run locally

### 1. Create a virtual environment

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
```

On Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Copy environment file

```bash
cp .env.example .env
```

### 4. Start the server

```bash
uvicorn app.main:app --reload
```

The API will be available at:

- `http://127.0.0.1:8000`
- Swagger docs: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`

## Core endpoints

### Health

- `GET /health`

### Users

- `POST /users/anonymous`
- `GET /users/{user_id}`
- `POST /users/{user_id}/reset`

### Moods

- `POST /users/{user_id}/moods`
- `GET /users/{user_id}/moods`
- `GET /users/{user_id}/moods/summary`

### Journals

- `POST /users/{user_id}/journals`
- `GET /users/{user_id}/journals`
- `DELETE /journals/{journal_id}`

### Sessions and messages

- `POST /users/{user_id}/sessions`
- `GET /users/{user_id}/sessions`
- `GET /sessions/{session_id}/messages`
- `POST /sessions/{session_id}/messages`
- `WS /ws/sessions/{session_id}`
- `WS /ws` (legacy-compatible with current Flutter WebSocket payloads)

### Notifications

- `GET /users/{user_id}/notifications`
- `POST /notifications/{notification_id}/read`

### Future AI placeholders

- `POST /ai/match`
- `POST /ai/summarize`
- `POST /ai/moderate`

These currently return `501 Not Implemented` and are only meant to reserve a clean integration surface for future AI features such as Bedrock.

## Database notes

- Default database: SQLite
- Configured through `DATABASE_URL`
- To move to PostgreSQL later, swap the connection string and add the appropriate database driver

## WebSocket notes

The realtime chat layer uses a simple in-memory connection manager keyed by `session_id`. This is intentionally lightweight and good for local development or a hackathon environment. For multi-instance deployment later, it can be replaced with Redis or another shared pub/sub layer.

The `/ws` endpoint supports the existing Flutter `action` payloads (`joinCommunity`, `sendMessage`) so the mobile app can connect without code changes.

## Suggested next steps

- Add auth/session verification around user operations
- Add tests for routes and services
- Add Alembic migrations when the schema becomes more stable
- Plug `/ai/*` endpoints into a real AI provider once the team is ready
