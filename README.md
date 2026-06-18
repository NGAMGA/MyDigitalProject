# Komi App

Application mobile Flutter du projet Komi.

Le repo contient maintenant :
- le front Flutter dans `lib/`
- le backend FastAPI d'authentification dans `backend/`

Le site vitrine n'heberge plus l'API.

## Vision actuelle du produit

Komi aide l'utilisateur a :
- se creer un compte et se reconnecter sans friction
- constituer une liste de courses
- importer cette liste par photo ou galerie a terme
- saisir manuellement des items de liste
- obtenir un bilan nutritionnel global de la liste
- parcourir des recettes et en enregistrer en favoris

Important :
- on ne parle plus de ticket de caisse comme flux principal
- le coeur du MVP cote liste de courses est la liste elle-meme
- l'OCR photo / galerie n'est pas encore branche en production dans l'app

## Etat actuel de l'application

Ce qui fonctionne aujourd'hui :
- inscription et connexion via le backend FastAPI
- session locale gardee 30 jours sur l'appareil
- home mobile reworkee
- page `Ma liste de course` reworkee
- ajout manuel d'un item de liste depuis une zone de saisie
- import d'une image de liste depuis photo ou galerie
- analyse OCR cote backend pour extraire les lignes produits d'une liste lisible
- filtrage alimentaire des items via TheMealDB + alias francais locaux
- calcul local d'un `Bilan des courses` a partir des items presents
- recherche de recettes via TheMealDB
- detail recette
- favoris de recettes
- suggestions de menus et recherche avancee via le backend
- panier de recettes avec generation d'une liste de courses
- abonnement Standard visible comme version actuelle par defaut
- creation d'une session Stripe Checkout pour passer Premium
- page profil et page favoris reworkees visuellement

Ce qui est encore partiel ou maquette :
- suggestions de menus basees sur la liste reelle
- confirmation automatique du paiement par webhook Stripe
- restrictions Standard / Premium
- edition persistante du profil
- historique utilisateur complet

## Architecture rapide

```text
my_digital_project_app/
|- lib/
|  |- features/auth/        # auth Flutter
|  |- features/home/        # home reworkee
|  |- features/scan/        # ma liste de course
|  |- features/profile/     # profil
|  |- screens/              # recettes / favoris / detail
|  |- providers/            # etat local (favoris, liste de courses)
|  |- services/             # APIs externes
|- backend/                 # API FastAPI
|- assets/images/           # logos / images
```

## APIs utilisees

- Auth Komi locale : `http://127.0.0.1:8000/api/v1`
- Health backend : `http://127.0.0.1:8000/health`
- Recettes : TheMealDB via `MealApiService`

## Lancer le projet

### 1. Lancer le backend

Voir `backend/README.md` pour le detail.

Option rapide sans Docker :

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
$env:DATABASE_URL="sqlite:///./komi_dev.db"
.\.venv\Scripts\uvicorn app.main:app --host 127.0.0.1 --port 8000
```

### 2. Lancer l'app Flutter

Depuis la racine du repo :

```powershell
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5454
```

URL locale web :

```text
http://127.0.0.1:5454
```

### 3. Verifications utiles

```powershell
flutter analyze
flutter test
```

## Fonctionnement des ecrans principaux

### Auth

- l'app appelle `POST /api/v1/auth/register`
- l'app appelle `POST /api/v1/auth/login`
- le token et l'utilisateur sont stockes localement
- la session expire au bout de 30 jours si elle n'est pas renouvellee

### Home

- affiche le prenom de l'utilisateur connecte
- affiche un `Bilan des courses`
- ce bilan est calcule localement a partir de la liste de courses courante
- affiche des suggestions de recettes chargees depuis TheMealDB

### Ma liste de course

- permet de prendre en photo la liste
- permet d'importer une image depuis la galerie
- permet d'ecrire un item manuellement maintenant
- envoie l'image au backend pour OCR
- quand un item est saisi, l'app essaie de le reconnaitre via un petit catalogue local
- quand une image est analysee, l'app recupere les items detectes et les ajoute a la liste courante
- les textes non alimentaires sont ignores avant ajout
- si l'item est reconnu, ses infos sont reutilisees
- sinon, l'app cree un item manuel generique

### Recettes

- recherche de recettes via API externe
- navigation type swipe
- ouverture du detail recette
- ajout / retrait des favoris
- le backend expose aussi des suggestions, une recherche avancee et un panier de recettes
- le panier peut generer une liste d'ingredients depuis les recettes selectionnees

### Abonnement et Stripe

- le plan Standard est affiche comme la version actuelle incluse par defaut
- le plan Premium est affiche a `6 € par mois`
- le bouton Premium appelle `POST /api/v1/subscription/checkout/premium`
- le backend cree une session Stripe Checkout en mode abonnement
- Stripe renvoie une URL de paiement que l'app ouvre dans le navigateur

Variables backend necessaires :

```powershell
$env:STRIPE_SECRET_KEY="sk_test_..."
$env:STRIPE_PREMIUM_PRICE_ID="price_..."
$env:STRIPE_SUCCESS_URL="http://127.0.0.1:5454/#/subscription/success"
$env:STRIPE_CANCEL_URL="http://127.0.0.1:5454/#/subscription/cancel"
```

Important : pour activer automatiquement le compte Premium apres paiement, il faudra ajouter un webhook Stripe `checkout.session.completed`.

## Notes pour l'equipe

- le backend a ete deplace dans ce repo pour que toute l'equipe puisse lancer front + API depuis le meme depot
- si l'app semble "connectee en boucle", il faut verifier que le backend tourne bien sur `127.0.0.1:8000`
- plusieurs ecrans ont deja le rendu cible, mais pas encore tout le comportement metier final
