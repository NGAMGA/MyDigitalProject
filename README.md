# Komi - Application mobile et API

Komi est une application mobile Flutter accompagnee d'une API FastAPI. Le projet a pour objectif d'aider les utilisateurs a mieux comprendre leurs courses alimentaires, a retrouver des idees de recettes et a gerer leur compte depuis une meme application.

Le projet est realise dans un cadre scolaire MyDigitalSchool.

## Objectifs du projet

Komi vise a simplifier le suivi alimentaire apres les courses. L'application doit permettre de transformer une liste de produits en informations utiles pour l'utilisateur : produits alimentaires retenus, suggestions de recettes, profil utilisateur, abonnement et donnees de compte.

Objectifs principaux :

- centraliser les produits issus d'une liste de courses;
- identifier les produits alimentaires dans une liste mixte;
- proposer une experience mobile simple pour explorer des recettes;
- permettre la creation et la connexion a un compte utilisateur;
- gerer les informations de profil, factures et abonnements;
- preparer l'integration future de donnees nutritionnelles plus avancees.

## Cible

Le projet s'adresse principalement a :

- des utilisateurs qui veulent mieux suivre leur alimentation;
- des personnes en reequiilibrage alimentaire;
- des jeunes actifs ou etudiants qui font leurs courses en supermarche;
- des utilisateurs qui veulent gagner du temps pour trouver des recettes;
- des personnes sensibles a la qualite et a la composition des produits achetes.

## Fonctionnalites principales

### Application Flutter

- Onboarding et ecrans d'authentification.
- Creation de compte et connexion via l'API Komi.
- Stockage local de la session utilisateur.
- Page d'accueil avec acces aux recettes.
- Recherche de recettes.
- Exploration de recettes par origine/pays.
- Detail d'une recette.
- Favoris locaux.
- Page profil utilisateur.
- Mise a jour des informations de profil.
- Preparation des parcours de scan/liste de courses.

### Backend FastAPI

- Authentification par JWT.
- Inscription et connexion utilisateur.
- Recuperation et modification du profil.
- Changement et reinitialisation du mot de passe.
- Gestion des abonnements.
- Catalogue de plans d'abonnement.
- Annulation d'abonnement.
- Generation de facture lors d'un changement vers un plan payant.
- Liste des factures utilisateur.
- Filtrage alimentaire d'une liste de courses.
- Healthcheck API.

### Fonctionnalites en cours ou prevues

- Analyse OCR d'une image de ticket ou de liste de courses.
- Validation avancee des produits detectes.
- Integration nutritionnelle avec une base de donnees alimentaire.
- Paiement reel des abonnements.
- Synchronisation complete entre scan, liste de courses et recommandations.

## API utilisees

### API interne Komi

L'API interne est developpee avec FastAPI et expose les routes sous le prefixe :

```text
http://127.0.0.1:8000/api/v1
```

Endpoints principaux :

- `GET /health`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`
- `GET /api/v1/users/me`
- `PATCH /api/v1/users/me`
- `POST /api/v1/users/change-password`
- `GET /api/v1/subscription/plans`
- `GET /api/v1/subscription/me`
- `PUT /api/v1/subscription/me`
- `POST /api/v1/subscription/me/cancel`
- `GET /api/v1/invoices/me`
- `POST /api/v1/invoices/me/demo`
- `POST /api/v1/food-filter/filter`

### TheMealDB

L'application utilise TheMealDB pour la recherche et l'exploration de recettes :

```text
https://www.themealdb.com/api/json/v1/1
```

Cette URL peut etre surchargee au lancement avec `MEAL_API_BASE`.

### MyMemory Translation

Un service de traduction utilise l'API MyMemory :

```text
https://api.mymemory.translated.net
```

### Open Food Facts

Open Food Facts est une source de donnees alimentaire envisagee pour les evolutions nutritionnelles :

```text
https://world.openfoodfacts.org/data
```

## Stack technique

### Frontend mobile

- Flutter
- Dart
- Provider
- Dio
- http
- Shared Preferences
- Cached Network Image
- Flutter SVG
- Image Picker
- URL Launcher

### Backend

- Python
- FastAPI
- SQLAlchemy
- PostgreSQL ou SQLite en local
- JWT Bearer
- Passlib / bcrypt
- Pydantic Settings
- Uvicorn

### Outils

- Git / GitHub
- VS Code
- Android Studio
- Docker et Docker Compose, optionnel pour le backend

## Structure du projet

```text
.
|-- android/                 # Projet Android Flutter
|-- assets/                  # Images et assets Flutter
|-- backend/                 # API FastAPI
|   |-- app/
|   |   |-- routers/         # Routes API
|   |   |-- main.py          # Entree FastAPI
|   |   |-- models.py        # Modeles SQLAlchemy
|   |   |-- schemas.py       # Schemas Pydantic
|   |   |-- database.py      # Connexion DB
|   |   `-- security.py      # JWT et mots de passe
|   |-- tests/               # Tests backend
|   |-- requirements.txt
|   `-- docker-compose.yml
|-- lib/                     # Code Flutter
|   |-- app/
|   |-- features/
|   |-- models/
|   |-- providers/
|   |-- screens/
|   |-- services/
|   `-- widgets/
|-- test/                    # Tests Flutter
|-- web/
|-- windows/
|-- pubspec.yaml
`-- README.md
```

## Installation

### Prerequis

- Git
- Flutter SDK compatible avec Dart `^3.5.4`
- Android Studio avec SDK Android
- Un emulateur Android ou un telephone Android en mode developpeur
- Python 3.11 ou plus recent
- PostgreSQL, si lancement backend avec PostgreSQL local
- Docker Desktop, optionnel

Verifier l'environnement Flutter :

```powershell
flutter doctor
```

Cloner le projet puis se placer dans le dossier :

```powershell
git clone <url-du-repo>
cd "App Komi"
```

Installer les dependances Flutter :

```powershell
flutter pub get
```

## Lancer le backend

Deux modes sont possibles : avec Docker/PostgreSQL ou sans Docker avec SQLite.

### Option 1 - Backend avec SQLite local

Cette option est la plus simple pour developper rapidement.

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
$env:DATABASE_URL="sqlite:///./komi_dev.db"
.\.venv\Scripts\uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

API :

```text
http://127.0.0.1:8000
```

Documentation Swagger :

```text
http://127.0.0.1:8000/docs
```

### Option 2 - Backend avec Docker

```powershell
cd backend
copy .env.example .env
docker compose up -d --build
```

Services exposes :

```text
API: http://127.0.0.1:8000
Docs: http://127.0.0.1:8000/docs
PostgreSQL: localhost:5432
```

## Lancer l'application Flutter

Depuis la racine du projet :

```powershell
flutter pub get
flutter run
```

Par defaut, l'application appelle l'API Komi locale :

```text
http://127.0.0.1:8000/api/v1
```

Pour lancer en precisant explicitement l'URL de l'API :

```powershell
flutter run --dart-define=KOMI_API_BASE=http://127.0.0.1:8000/api/v1
```

Pour surcharger l'API de recettes :

```powershell
flutter run --dart-define=MEAL_API_BASE=https://www.themealdb.com/api/json/v1/1
```

Sur un emulateur Android, `127.0.0.1` pointe vers l'emulateur lui-meme. Si l'app n'arrive pas a joindre le backend local, utiliser :

```powershell
flutter run --dart-define=KOMI_API_BASE=http://10.0.2.2:8000/api/v1
```

## Tests

### Tests backend

Depuis la racine du projet :

```powershell
backend\.venv\Scripts\python -m unittest discover -s backend\tests
backend\.venv\Scripts\python -m compileall backend\app backend\tests
```

### Tests Flutter

```powershell
flutter test
```

## Exemple de filtrage alimentaire

Requete :

```http
POST /api/v1/food-filter/filter
Content-Type: application/json
```

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

## Variables d'environnement

### Backend

Les variables principales sont definies dans `backend/.env.example` :

```text
DATABASE_URL=postgresql+psycopg://komi:komi@localhost:5432/komi
JWT_SECRET_KEY=change-this-secret-in-production
JWT_EXPIRE_MINUTES=1440
CORS_ORIGINS=http://127.0.0.1:4173,http://localhost:4173,http://127.0.0.1:8080,http://localhost:8080,null
```

### Flutter

Variables utilisables avec `--dart-define` :

```text
KOMI_API_BASE=http://127.0.0.1:8000/api/v1
MEAL_API_BASE=https://www.themealdb.com/api/json/v1/1
```

## Branches et collaboration

Branche de travail backend actuelle :

```text
rework-home-front
```

Les developpements lies a la gestion des abonnements et au filtrage alimentaire ont ete prepares dans une branche dediee afin de pouvoir etre integres proprement dans `rework-home-front`.

Avant de travailler :

```powershell
git fetch origin
git switch rework-home-front
git pull
```

Avant de pousser :

```powershell
git status
git add .
git commit -m "Update backend subscriptions and food filtering"
git push
```

## Notes importantes

- Le dossier `backend/` contient l'API utilisee par l'application.
- Le backend peut tourner sans Docker avec SQLite pour simplifier le developpement local.
- Les routes protegees necessitent un token JWT obtenu via la connexion.
- Les fonctionnalites OCR et paiement reel sont encore a finaliser.
