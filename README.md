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
- importer cette liste par photo ou galerie
- saisir manuellement des items de liste
- obtenir un bilan nutritionnel global de la liste
- parcourir des recettes et en enregistrer en favoris

Important :
- on ne parle plus de ticket de caisse comme flux principal
- le coeur du MVP cote liste de courses est la liste elle-meme
- l'OCR photo / galerie est branche entre l'app Flutter et le backend

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
- essai Premium de 7 jours avec moyen de paiement collecte par Stripe
- debit automatique de 5,99 EUR par mois apres l'essai si l'utilisateur ne resilie pas
- resiliation et reactivation depuis la page profil
- suppression definitive du compte et des donnees associees
- mot de passe oublie, reinitialisation et changement de mot de passe
- liste de courses persistante par utilisateur
- suggestions calculees depuis les ingredients de la liste reelle
- limites Standard / Premium appliquees aux recommandations et a l'historique
- panier de recettes accessible dans l'app avec generation de liste de courses
- conseils nutritionnels Premium dans le detail des recettes
- page profil et page favoris reworkees visuellement

Ce qui est encore partiel ou maquette :
- donnees nutritionnelles generiques pour les produits inconnus
- synchronisation des favoris entre appareils

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
- l'app permet d'ajouter ou retirer des recettes du panier
- la liste generee est ajoutee a la liste de courses persistante
- les ingredients en doublon sont regroupes lors de la generation

### Compte

- le lien `Mot de passe oublie` lance la demande de reinitialisation
- un lien de reinitialisation ouvre l'ecran Flutter avec le token
- le mot de passe peut aussi etre change depuis la page profil
- la suppression du compte exige le mot de passe et la saisie de `SUPPRIMER`
- un abonnement Stripe actif est annule avant la suppression definitive

### Abonnement et Stripe

- le plan Standard est affiche comme la version actuelle incluse par defaut
- le plan Premium comprend 7 jours gratuits, puis coute `5,99 EUR par mois`
- le bouton Premium appelle `POST /api/v1/subscription/checkout/premium`
- le backend cree une session Stripe Checkout en mode abonnement avec `trial_period_days=7`
- Stripe collecte la carte pendant l'inscription, sans debit immediat
- sans resiliation, le premier debit intervient automatiquement a la fin des 7 jours
- `POST /api/v1/subscription/me/cancel` programme la resiliation a la fin de l'essai ou de la periode payee
- `POST /api/v1/subscription/me/resume` annule une resiliation programmee
- Stripe renvoie une URL de paiement que l'app ouvre dans le navigateur

Variables backend necessaires :

```powershell
$env:STRIPE_SECRET_KEY="sk_test_..."
$env:STRIPE_PREMIUM_PRICE_ID="price_..."
$env:STRIPE_WEBHOOK_SECRET="whsec_..."
$env:STRIPE_TRIAL_DAYS="7"
$env:STRIPE_SUCCESS_URL="http://127.0.0.1:5454/#/subscription/success"
$env:STRIPE_CANCEL_URL="http://127.0.0.1:5454/#/subscription/cancel"
```

Les webhooks Stripe `checkout.session.completed`, `customer.subscription.created`,
`customer.subscription.updated` et `customer.subscription.deleted` synchronisent
l'essai, le renouvellement et la resiliation. En developpement local, il faut
transmettre les evenements avec Stripe CLI vers `/api/v1/subscription/webhook`.

## Notes pour l'equipe

- le backend a ete deplace dans ce repo pour que toute l'equipe puisse lancer front + API depuis le meme depot
- si l'app semble "connectee en boucle", il faut verifier que le backend tourne bien sur `127.0.0.1:8000`
- plusieurs ecrans ont deja le rendu cible, mais pas encore tout le comportement metier final
