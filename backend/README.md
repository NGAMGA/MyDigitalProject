# Komi API

Backend FastAPI utilise par l'application Flutter Komi pour l'authentification, les donnees de compte, les abonnements, les factures et le filtrage alimentaire.

## Stack

- Python
- FastAPI
- SQLAlchemy
- PostgreSQL ou SQLite
- JWT Bearer
- Pydantic
- Uvicorn

## Endpoints

### Sante

- `GET /health`

### Authentification

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`

### Utilisateur

- `GET /api/v1/users/me`
- `PATCH /api/v1/users/me`
- `POST /api/v1/users/change-password`

### Abonnements

- `GET /api/v1/subscription/plans`
- `GET /api/v1/subscription/me`
- `PUT /api/v1/subscription/me`
- `POST /api/v1/subscription/me/cancel`

Plans disponibles :

- `Free`
- `Premium`
- `Pro`

Le changement vers un plan payant genere une facture. Les plans payants actifs recoivent une date de renouvellement si aucune date n'est fournie.

### Factures

- `GET /api/v1/invoices/me`
- `POST /api/v1/invoices/me/demo`

### Filtrage alimentaire

- `POST /api/v1/food-filter/filter`

Exemple :

```json
{
  "items": [
    "pommes",
    "lessive",
    { "name": "riz basmati", "quantity": "1 kg" },
    "papier toilette",
    "tomates"
  ]
}
```

Reponse simplifiee :

```json
{
  "foodItems": [
    { "name": "pommes", "category": "Alimentaire" },
    { "name": "riz basmati", "category": "Alimentaire" },
    { "name": "tomates", "category": "Alimentaire" }
  ],
  "rejectedItems": [
    { "name": "lessive", "reason": "Produit non alimentaire detecte" },
    { "name": "papier toilette", "reason": "Produit non alimentaire detecte" }
  ],
  "totalItems": 5,
  "foodCount": 3,
  "rejectedCount": 2
}
```

## Installation locale

Depuis le dossier `backend` :

```powershell
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
```

## Lancement sans Docker

Mode SQLite :

```powershell
$env:DATABASE_URL="sqlite:///./komi_dev.db"
.\.venv\Scripts\uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

API :

```text
http://127.0.0.1:8000
```

Docs Swagger :

```text
http://127.0.0.1:8000/docs
```

## Lancement avec Docker

```powershell
copy .env.example .env
docker compose up -d --build
```

Services exposes :

```text
API: http://127.0.0.1:8000
Docs: http://127.0.0.1:8000/docs
PostgreSQL: localhost:5432
```

Variables Docker par defaut :

```text
POSTGRES_DB=komi
POSTGRES_USER=komi
POSTGRES_PASSWORD=komi
DATABASE_URL=postgresql+psycopg://komi:komi@db:5432/komi
```

## Variables d'environnement

Exemple dans `.env.example` :

```text
DATABASE_URL=postgresql+psycopg://komi:komi@localhost:5432/komi
JWT_SECRET_KEY=change-this-secret-in-production
JWT_EXPIRE_MINUTES=1440
CORS_ORIGINS=http://127.0.0.1:4173,http://localhost:4173,http://127.0.0.1:8080,http://localhost:8080,null
```

## Tests

Depuis la racine du projet :

```powershell
backend\.venv\Scripts\python -m unittest discover -s backend\tests
backend\.venv\Scripts\python -m compileall backend\app backend\tests
```

Depuis le dossier `backend` :

```powershell
.\.venv\Scripts\python -m unittest discover -s tests
.\.venv\Scripts\python -m compileall app tests
```

## Notes

- Les routes utilisateur, abonnement et facture necessitent un token JWT.
- Les tables sont creees automatiquement au demarrage via SQLAlchemy.
- `ensure_schema_compatibility` ajoute les colonnes de profil manquantes sur une base existante.
- Pour un developpement rapide, SQLite est suffisant.
