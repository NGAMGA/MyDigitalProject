# Komi API

Backend FastAPI utilise par l'application Flutter pour l'authentification et les donnees compte.

## Lancement avec Docker

```powershell
cd backend
docker compose up -d --build
```

Services exposes:

```text
API: http://127.0.0.1:8000
Docs: http://127.0.0.1:8000/docs
PostgreSQL: localhost:5432
```

Base de donnees locale Docker:

```text
POSTGRES_DB=komi
POSTGRES_USER=komi
POSTGRES_PASSWORD=komi
DATABASE_URL=postgresql+psycopg://komi:komi@db:5432/komi
```

## Lancement sans Docker

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
$env:DATABASE_URL="sqlite:///./komi_dev.db"
.\.venv\Scripts\uvicorn app.main:app --host 127.0.0.1 --port 8000
```

L'application Flutter appelle par defaut:

```text
http://127.0.0.1:8000/api/v1
```
