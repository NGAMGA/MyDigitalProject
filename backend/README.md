# Komi API

Backend FastAPI utilise par l'application Flutter.

Aujourd'hui, cette API sert surtout a :
- l'inscription
- la connexion
- la gestion de session cote front
- l'analyse OCR d'images de listes de courses
- le filtrage alimentaire des items detectes
- la creation d'une session Stripe Checkout pour l'abonnement Premium
- quelques routes utilisateur / abonnement deja presentes dans le backend

## URLs utiles

```text
API base: http://127.0.0.1:8000
Health:   http://127.0.0.1:8000/health
Docs:     http://127.0.0.1:8000/docs
Prefixe:  http://127.0.0.1:8000/api/v1
```

## Endpoints auth utilises par l'app

```text
POST /api/v1/auth/register
POST /api/v1/auth/login
```

Autres endpoints disponibles dans le backend :

```text
POST /api/v1/auth/forgot-password
POST /api/v1/auth/reset-password
POST /api/v1/shopping-lists/analyze-image
POST /api/v1/shopping-lists/validate-items
POST /api/v1/subscription/checkout/premium
POST /api/v1/subscription/webhook
POST /api/v1/menus/suggestions
GET  /api/v1/menus/search
GET  /api/v1/menus/cart
POST /api/v1/menus/cart/add
DELETE /api/v1/menus/cart/{meal_id}
POST /api/v1/menus/cart/generate-list
```

## Lancement avec Docker

Depuis `backend/` :

```powershell
docker compose up -d --build
```

Services exposes :

```text
API: http://127.0.0.1:8000
PostgreSQL: localhost:5432
```

Configuration Docker locale :

```text
POSTGRES_DB=komi
POSTGRES_USER=komi
POSTGRES_PASSWORD=komi
DATABASE_URL=postgresql+psycopg://komi:komi@db:5432/komi
```

## Lancement sans Docker

Depuis `backend/` :

```powershell
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
$env:DATABASE_URL="sqlite:///./komi_dev.db"
$env:STRIPE_SECRET_KEY="sk_test_..."
$env:STRIPE_PREMIUM_PRICE_ID="price_..."
$env:STRIPE_WEBHOOK_SECRET="whsec_..."
.\.venv\Scripts\uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Ce mode est pratique pour l'equipe quand Docker n'est pas disponible.

## Comment le front s'y connecte

Le front Flutter pointe par defaut vers :

```text
http://127.0.0.1:8000/api/v1
```

Cela est configure dans `lib/features/auth/data/auth_api_client.dart`.

Pour l'analyse OCR de liste :
- le front envoie l'image en multipart
- la route `POST /api/v1/shopping-lists/analyze-image` est protegee par le token utilisateur
- le backend renvoie le texte brut detecte et les items extraits
- les items non alimentaires sont renvoyes dans `rejectedItems`
- le filtre s'appuie sur la liste d'ingredients TheMealDB, avec un fallback local et des alias francais

Pour la saisie manuelle :
- le front appelle `POST /api/v1/shopping-lists/validate-items`
- seuls les aliments valides sont ajoutes a la liste

Pour les menus :
- les routes `/api/v1/menus` utilisent TheMealDB cote backend
- la recherche avancee et le panier necessitent un abonnement Premium
- le panier stocke les recettes choisies en base
- `POST /api/v1/menus/cart/generate-list` regroupe leurs ingredients

Pour Stripe :
- le front appelle `POST /api/v1/subscription/checkout/premium`
- la route exige un token utilisateur
- le backend utilise `STRIPE_SECRET_KEY` et `STRIPE_PREMIUM_PRICE_ID`
- le prix Stripe doit etre un Price recurrent configure a `6 € / mois`
- la route renvoie `{ "url": "https://checkout.stripe.com/..." }`
- si Stripe n'est pas configure, la route renvoie une erreur 503 lisible
- le webhook `checkout.session.completed` active ensuite le plan Premium

Variables optionnelles :

```text
STRIPE_SUCCESS_URL=http://127.0.0.1:5454/#/subscription/success
STRIPE_CANCEL_URL=http://127.0.0.1:5454/#/subscription/cancel
```

En local, Stripe CLI peut transmettre les evenements au backend :

```powershell
stripe listen --forward-to http://127.0.0.1:8000/api/v1/subscription/webhook
```

La commande affiche la valeur `whsec_...` a placer dans `STRIPE_WEBHOOK_SECRET`.

## Base de donnees

Deux modes possibles :
- Docker : PostgreSQL
- Local simple : SQLite avec `komi_dev.db`

Pour le dev local actuel, SQLite suffit pour tester inscription / connexion.

## Comportement utile a connaitre

- l'application Flutter memorise la session localement pendant 30 jours
- si le backend est coupe, les formulaires auth renverront une erreur de connexion
- les recettes ne passent pas par cette API : elles utilisent TheMealDB cote Flutter
