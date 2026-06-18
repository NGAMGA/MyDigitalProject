# Dossier de conception - Komi

**Projet :** application mobile Komi
**Contexte :** My Digital Project
**Date :** 16 juin 2026
**Version documentée :** état du dépôt local au 16 juin 2026

---

## 1. Présentation du projet

Komi est une application mobile conçue pour accompagner l'utilisateur dans la préparation de ses courses et dans la découverte de recettes. L'idée centrale du MVP n'est pas le ticket de caisse, mais la **liste de courses** : l'utilisateur peut créer ou importer une liste, faire reconnaître les aliments, consulter un bilan nutritionnel global et explorer des recettes associées à son univers alimentaire.

Le projet est organisé autour de deux parties principales :

- une application Flutter dans le dossier `lib/`, destinée aux usages mobile et web en développement ;
- une API FastAPI dans le dossier `backend/`, chargée de l'authentification, de la gestion utilisateur, de l'analyse OCR et de l'abonnement.

Le dépôt contient également les dossiers natifs Android, iOS et Web générés par Flutter, les ressources graphiques dans `assets/images/`, ainsi que la configuration Docker du backend.

## 2. Objectifs fonctionnels

L'application cherche à répondre à plusieurs besoins utilisateur :

- créer un compte et se reconnecter facilement ;
- conserver une session locale pendant une durée limitée ;
- constituer une liste de courses à partir d'une saisie manuelle ;
- importer une image de liste depuis la caméra ou la galerie ;
- extraire les aliments reconnus grâce à une analyse OCR côté backend ;
- ignorer les lignes non alimentaires avant l'ajout à la liste ;
- calculer un bilan nutritionnel global à partir des produits présents ;
- rechercher des recettes depuis TheMealDB ;
- consulter le détail d'une recette ;
- enregistrer des recettes en favoris ;
- consulter et modifier certaines informations du profil ;
- ouvrir une session Stripe Checkout pour passer à une formule Premium.

Le produit documenté correspond à un MVP avancé : plusieurs écrans sont déjà finalisés visuellement, mais certaines mécaniques métier restent partielles ou simulées.

## 3. Périmètre actuel

### Fonctionnel aujourd'hui

- Authentification par inscription et connexion via l'API FastAPI.
- Stockage local du token et de l'utilisateur avec `shared_preferences`.
- Session côté application valable 30 jours.
- Navigation principale en 5 onglets : accueil, recettes, liste de courses, favoris, profil.
- Ajout manuel d'aliments à la liste de courses.
- Import d'image depuis caméra ou galerie avec `image_picker`.
- Analyse OCR côté backend avec RapidOCR.
- Filtrage alimentaire via TheMealDB, alias français et catalogue local de secours.
- Bilan nutritionnel local calculé depuis la liste courante.
- Recherche et consultation de recettes via TheMealDB.
- Favoris persistés localement.
- Mise à jour partielle du profil utilisateur.
- Création d'une session Stripe Checkout pour le plan Premium.
- Exécution possible du backend avec Docker/PostgreSQL ou en local avec SQLite.

### Encore partiel

- Les suggestions de menus ne sont pas encore réellement personnalisées à partir de la liste de courses.
- Le webhook Stripe doit être configuré et relayé vers le backend pour activer automatiquement le compte Premium.
- Les restrictions entre les plans Standard/Free et Premium ne sont pas encore appliquées.
- L'historique complet des listes ou des achats n'est pas encore persistant.
- Le bilan nutritionnel repose sur un catalogue local et sur des valeurs génériques quand un produit n'est pas reconnu.
- Les favoris sont stockés localement, donc ils ne suivent pas encore l'utilisateur entre plusieurs appareils.

## 4. Architecture générale

L'architecture du projet est simple et adaptée à un MVP mobile :

```text
Utilisateur
   |
   v
Application Flutter
   |-- UI : écrans auth, home, liste, recettes, favoris, profil
   |-- Providers : session, favoris, liste de courses
   |-- Services : API Komi, OCR, profil, paiement, recettes
   |
   +--> API Komi FastAPI
   |       |-- Authentification JWT
   |       |-- Utilisateurs / profils
   |       |-- OCR liste de courses
   |       |-- Filtrage alimentaire
   |       |-- Abonnement Stripe
   |       +--> Base SQLAlchemy : PostgreSQL ou SQLite
   |
   +--> TheMealDB
           |-- Recherche de recettes
           |-- Ingrédients de référence
```
La séparation front/back permet de garder le code Flutter centré sur l'expérience utilisateur, tandis que les traitements sensibles ou plus lourds, comme l'authentification, l'OCR et le paiement, restent côté serveur.

## 5. Arborescence utile

```text
my_digital_project_app/
|-- lib/
|   |-- app/                     # application Flutter et shell principal
|   |-- features/auth/           # splash, choix auth, login, signup, modèles auth
|   |-- features/home/           # écran d'accueil
|   |-- features/scan/           # écran Ma liste de courses
|   |-- features/profile/        # écran profil et abonnement
|   |-- providers/               # état local avec ChangeNotifier
|   |-- services/                # appels API et services externes
|   |-- models/                  # modèles Meal, ShoppingProduct, OCR
|   |-- screens/                 # recherche, favoris, détail recette
|   |-- widgets/                 # composants réutilisables
|-- backend/
|   |-- app/
|   |   |-- routers/             # auth, users, subscriptions, invoices, shopping_lists
|   |   |-- main.py              # création FastAPI, CORS, routers, healthcheck
|   |   |-- models.py            # modèles SQLAlchemy
|   |   |-- schemas.py           # contrats Pydantic
|   |   |-- security.py          # mots de passe, JWT, reset token
|   |   |-- shopping_list_ocr.py # OCR et extraction des lignes
|   |   |-- food_filter.py       # validation alimentaire
|   |-- Dockerfile
|   |-- docker-compose.yml
|   |-- requirements.txt
|-- assets/images/               # logos et image de marque
|-- test/                        # tests Flutter existants
```

## 6. Frontend Flutter

### 6.1 Technologies

Le frontend utilise Flutter avec Dart 3.5.4. Les dépendances principales sont :

- `provider` pour l'état partagé ;
- `shared_preferences` pour la persistance locale légère ;
- `http` pour l'API Komi ;
- `dio` pour TheMealDB et la traduction ;
- `image_picker` pour la caméra et la galerie ;
- `cached_network_image` pour l'affichage optimisé des images distantes ;
- `flutter_svg` pour les logos ;
- `url_launcher` pour ouvrir Stripe Checkout.

### 6.2 Point d'entrée

Le point d'entrée est `lib/main.dart`, qui lance `KomiApp`. L'application initialise trois providers :

- `FavoritesProvider`, chargé des recettes favorites ;
- `ShoppingListProvider`, chargé de la liste de courses courante ;
- `UserSessionProvider`, chargé de l'utilisateur stocké localement.

La navigation principale est contenue dans `MainShell`, avec un `IndexedStack`. Ce choix conserve l'état des pages lorsque l'utilisateur change d'onglet.

### 6.3 Navigation

L'application possède cinq sections principales :

- **Accueil** : bilan des courses, liste actuelle, suggestions de recettes ;
- **Recettes** : recherche et navigation dans les recettes ;
- **Scan / Liste** : import photo, galerie et saisie manuelle ;
- **Favoris** : recettes enregistrées ;
- **Profil** : informations utilisateur et abonnement.

Le démarrage passe par `SplashPage`, qui vérifie la session locale et redirige vers l'expérience authentifiée ou vers les écrans d'authentification.

### 6.4 Gestion d'état

Le projet utilise une gestion d'état volontairement légère :

- `ShoppingListProvider` conserve les produits de la liste courante en mémoire.
- `FavoritesProvider` sauvegarde les favoris dans `shared_preferences`.
- `UserSessionProvider` garde en mémoire l'utilisateur courant et synchronise les modifications de profil.

Ce choix est cohérent pour un MVP : il limite la complexité tout en rendant les écrans réactifs.

## 7. Parcours utilisateur principaux

### 7.1 Inscription et connexion

Le front appelle :

- `POST /api/v1/auth/register` pour créer un compte ;
- `POST /api/v1/auth/login` pour se connecter.

L'API renvoie un token JWT et un objet utilisateur. Le front stocke :

- `komi_access_token` ;
- `komi_user` ;
- `komi_session_expires_at`.

La durée locale de session est fixée à 30 jours dans `AuthSessionStore`.

### 7.2 Accueil

La page d'accueil affiche :

- le prénom ou le nom de l'utilisateur ;
- un bilan des courses ;
- le nombre de produits de la liste actuelle ;
- des métriques nutritionnelles ;
- des suggestions de recettes récupérées depuis TheMealDB.

Le bilan est calculé localement depuis `ShoppingListProvider.summary`. Le score combine le Nutri-Score, des pénalités sur le sucre et le sel, et des bonus sur les fibres et protéines.

### 7.3 Liste de courses

La page liste de courses permet trois entrées :

- saisie manuelle ;
- photo avec la caméra ;
- image depuis la galerie.

Pour la saisie manuelle, le front envoie le texte à :

```text
POST /api/v1/shopping-lists/validate-items
```

Pour l'image, le front envoie un multipart à :

```text
POST /api/v1/shopping-lists/analyze-image
```

Le backend renvoie :

- `rawText` : texte brut détecté ;
- `items` : aliments acceptés ;
- `rejectedItems` : lignes ignorées car non alimentaires.

Les aliments acceptés sont ajoutés à la liste courante. Si un produit correspond au petit catalogue local, ses valeurs nutritionnelles sont utilisées ; sinon, un produit générique est créé.

### 7.4 Recettes

Les recettes ne transitent pas par l'API Komi. Le service Flutter `MealApiService` interroge directement TheMealDB :

- `/search.php?s=...` pour la recherche ;
- `/lookup.php?i=...` pour le détail ;
- `/filter.php?a=...` pour les recettes par zone géographique.

Le modèle `Meal` sait lire les données de recherche, les données détaillées, et les données stockées localement pour les favoris.

### 7.5 Favoris

Les favoris sont gérés par `FavoritesProvider`. Ils sont encodés en JSON puis stockés dans `shared_preferences` sous la clé :

```text
komi_favorite_meals
```

La persistance est locale : elle suffit pour une démo et un usage mono-appareil, mais elle devra être déplacée côté backend pour une synchronisation multi-appareils.

### 7.6 Profil et abonnement

La page profil lit l'utilisateur local, permet de modifier certains champs et appelle `ProfileService.updateMe`. Les modifications sont ensuite réinjectées dans `UserSessionProvider`.

Pour le passage Premium, le front appelle :

```text
POST /api/v1/subscription/checkout/premium
```

L'API crée une session Stripe Checkout en mode abonnement et renvoie une URL. Le front ouvre cette URL dans le navigateur avec `url_launcher`.

## 8. Backend FastAPI

### 8.1 Technologies

Le backend utilise :

- FastAPI pour les routes HTTP ;
- Uvicorn comme serveur ASGI ;
- SQLAlchemy 2 pour les modèles et sessions ;
- PostgreSQL via `psycopg` en Docker ;
- SQLite possible en local simple ;
- Pydantic et Pydantic Settings pour les schémas et la configuration ;
- `python-jose` pour les JWT ;
- `passlib` et `bcrypt` pour les mots de passe ;
- RapidOCR, Pillow et NumPy pour l'OCR ;
- Stripe pour le paiement.

### 8.2 Configuration

La configuration est centralisée dans `backend/app/config.py`. Les variables importantes sont :

- `DATABASE_URL` ;
- `JWT_SECRET_KEY` ;
- `JWT_EXPIRE_MINUTES` ;
- `CORS_ORIGINS` ;
- `STRIPE_SECRET_KEY` ;
- `STRIPE_PREMIUM_PRICE_ID` ;
- `STRIPE_SUCCESS_URL` ;
- `STRIPE_CANCEL_URL`.

En développement, le backend peut être lancé :

- avec Docker Compose : API + PostgreSQL ;
- sans Docker : Uvicorn + SQLite.

### 8.3 Routes principales

```text
GET  /health

POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/forgot-password
POST /api/v1/auth/reset-password

GET   /api/v1/users/me
PATCH /api/v1/users/me
POST  /api/v1/users/change-password

POST /api/v1/shopping-lists/analyze-image
POST /api/v1/shopping-lists/validate-items

GET  /api/v1/subscription/me
PUT  /api/v1/subscription/me
POST /api/v1/subscription/checkout/premium

GET  /api/v1/invoices/me
POST /api/v1/invoices/me/demo
```

Les routes sensibles utilisent `get_current_user`, qui lit le bearer token, décode le JWT et récupère l'utilisateur en base.

## 9. Modèle de données

Le backend possède quatre tables principales :

### User

Contient l'identité et le profil :

- identifiant UUID ;
- nom complet ;
- prénom, nom ;
- e-mail unique ;
- téléphone ;
- date de naissance ;
- pays ;
- bio ;
- avatar en data URL ;
- hash du mot de passe ;
- date de création.

### Subscription

Contient l'état d'abonnement :

- utilisateur lié ;
- plan ;
- statut ;
- date de renouvellement ;
- date de mise à jour.

### Invoice

Contient les factures :

- référence ;
- utilisateur lié ;
- date d'émission ;
- libellé ;
- montant en centimes ;
- statut.

### PasswordResetToken

Contient les jetons de réinitialisation :

- utilisateur lié ;
- hash du token ;
- date d'expiration ;
- date de création ;
- date d'utilisation éventuelle.

## 10. OCR et filtrage alimentaire

Le traitement d'image suit ce flux :

```text
Image envoyée par le front
   |
   v
Contrôle du type de fichier
   |
   v
Préparation de plusieurs variantes d'image
   |-- image originale
   |-- niveaux de gris contrastés
   |-- image renforcée
   |-- binaire
   |-- binaire inversée
   |
   v
RapidOCR sur chaque variante
   |
   v
Choix du meilleur résultat
   |
   v
Nettoyage des lignes détectées
   |
   v
Filtrage alimentaire
   |
   v
Réponse API : aliments acceptés + lignes rejetées
```

Le choix du meilleur résultat tient compte :

- du nombre d'aliments acceptés ;
- de la somme des confiances OCR ;
- de la quantité de texte brut détecté.

Le filtre alimentaire s'appuie sur :

- la liste d'ingrédients TheMealDB ;
- une liste locale de termes alimentaires ;
- des alias français vers des termes anglais ;
- une normalisation sans accents.

Cette approche est intéressante pour un MVP, car elle donne un résultat exploitable sans entraîner de modèle spécifique.

## 11. Sécurité

Plusieurs mécanismes sont déjà en place :

- les mots de passe sont hashés avec bcrypt ;
- une politique de mot de passe impose longueur, majuscule, minuscule, chiffre et caractère spécial ;
- certains mots de passe trop communs sont refusés ;
- le mot de passe ne doit pas contenir le nom ou l'e-mail ;
- les sessions API utilisent des JWT signés ;
- les routes privées exigent un bearer token ;
- les tokens de réinitialisation de mot de passe sont stockés hashés ;
- les erreurs de validation FastAPI sont transformées en messages lisibles.

Points à renforcer avant production :

- remplacer la clé JWT par défaut ;
- désactiver `EXPOSE_PASSWORD_RESET_LINK_IN_RESPONSE` en production ;
- restreindre `CORS_ORIGINS` au lieu de `*` ;
- configurer le secret du webhook Stripe selon l'environnement ;
- éviter de stocker durablement les avatars sous forme de data URL en base si le volume augmente ;
- ajouter des limites de taille d'image et éventuellement du rate limiting.

## 12. Paiement et abonnement

L'abonnement Premium est prévu à 6 euros par mois. Le backend utilise `STRIPE_PREMIUM_PRICE_ID`, qui doit correspondre à un Price Stripe récurrent.

Flux actuel :

```text
Utilisateur clique sur Premium
   |
   v
Flutter appelle /subscription/checkout/premium
   |
   v
FastAPI crée une session Stripe Checkout
   |
   v
Stripe renvoie une URL
   |
   v
Flutter ouvre l'URL dans le navigateur
```

Après paiement, le webhook écoute `checkout.session.completed`, vérifie la signature Stripe, retrouve l'utilisateur via `client_reference_id` ou `metadata.user_id`, puis met à jour la table `subscriptions`. En local, Stripe CLI doit transmettre les événements vers le backend.

## 13. Tests et qualité

Le projet contient des tests Flutter dans `test/widget_test.dart`.

Ils vérifient :

- l'affichage du texte de chargement sur la splash page ;
- le rendu des écrans d'authentification sur plusieurs tailles mobiles ;
- l'absence d'overflow visible pendant ces rendus.

Les tests actuels sécurisent surtout la partie UI des écrans d'authentification. Pour renforcer le dossier qualité, il serait pertinent d'ajouter :

- des tests unitaires sur `ShoppingListProvider.summary` ;
- des tests sur la validation de session dans `AuthSessionStore` ;
- des tests backend sur inscription, connexion, token invalide ;
- des tests backend sur `validate-items` ;
- un test d'intégration minimal front/back pour le parcours login + ajout manuel.

## 14. Choix de conception

### Flutter pour l'expérience mobile

Flutter permet de produire une interface mobile cohérente, fluide et facilement adaptable au web pour les démonstrations. Le projet conserve aussi les dossiers Android et iOS, ce qui permet une évolution vers une vraie distribution mobile.

### Provider plutôt qu'une architecture plus lourde

L'utilisation de `provider` est suffisante pour le périmètre actuel. Les états sont peu nombreux et clairement séparés : session, favoris, liste de courses.

### Backend intégré au même dépôt

Le backend a été déplacé dans le même dépôt que l'app pour faciliter le lancement par l'équipe. C'est pratique pour un projet scolaire ou un MVP, car tout le monde peut récupérer un seul dépôt et lancer front + API.

### OCR côté serveur

Mettre l'OCR côté backend évite d'alourdir l'application mobile et garde la possibilité d'améliorer le traitement sans publier une nouvelle version de l'app.

### TheMealDB pour accélérer le MVP

TheMealDB fournit rapidement des recettes, des ingrédients et des images. Cette dépendance externe permet de construire un parcours complet sans créer immédiatement une base de recettes interne.

## 15. Limites connues

- La liste de courses n'est pas encore persistée côté backend.
- Les produits ajoutés manuellement ont parfois des données nutritionnelles génériques.
- Les recettes proposées sur l'accueil ne sont pas encore calculées à partir de la liste réelle.
- Les favoris sont stockés localement.
- Le webhook Stripe doit être configuré sur chaque environnement pour mettre à jour automatiquement le statut Premium.
- Les droits Premium ne sont pas encore appliqués dans le front.
- Les textes de l'application contiennent encore quelques formulations à homogénéiser.
- Le système OCR dépend de la qualité de l'image et de la lisibilité de l'écriture.

## 16. Évolutions proposées

Priorités recommandées :

1. Persister les listes de courses côté backend.
2. Déployer et configurer le webhook Stripe sur l'environnement de production.
3. Synchroniser les favoris avec le compte utilisateur.
4. Calculer les suggestions de recettes depuis les ingrédients réellement présents.
5. Ajouter une base produits plus complète ou connecter Open Food Facts.
6. Ajouter des tests backend automatisés.
7. Ajouter une gestion claire des limites Free/Premium.
8. Prévoir un stockage média dédié pour les avatars.

## 17. Lancement du projet

### Backend sans Docker

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
$env:DATABASE_URL="sqlite:///./komi_dev.db"
.\.venv\Scripts\uvicorn app.main:app --host 127.0.0.1 --port 8000
```

### Backend avec Docker

```powershell
cd backend
docker compose up -d --build
```

### Application Flutter

```powershell
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5454
```

URL locale :

```text
http://127.0.0.1:5454
```

### Vérifications

```powershell
flutter analyze
flutter test
```

## 18. Annexes à joindre séparément

Ce dossier peut être complété avec :

- diagramme d'architecture front/back ;
- diagramme de séquence inscription/connexion ;
- diagramme de séquence import OCR ;
- modèle conceptuel de données ;
- captures d'écran des écrans principaux ;
- extrait de la documentation Swagger `/docs` ;
- preuve de test `flutter test` ;
- extrait de configuration Docker ;
- maquettes ou éléments graphiques de marque.

## Conclusion

Komi dispose déjà d'une base solide pour un MVP : une application Flutter structurée, une API FastAPI fonctionnelle, une authentification réelle, une reconnaissance OCR côté serveur, une recherche de recettes externe et un début de parcours d'abonnement. Les choix techniques sont cohérents avec un projet mobile évolutif : ils permettent de démontrer un parcours complet tout en gardant des pistes claires pour passer d'un prototype avancé à une version plus robuste.

