# Diapo oral - Partie front / produit Komi

## Slide 1 - Komi, le concept

**A afficher :**
- Application mobile Flutter
- Aide a preparer ses courses
- Liste de courses, bilan nutritionnel, recettes

**Ce que je dis :**

Bonjour, je vais vous presenter ma partie du projet Komi.
Komi est une application mobile developpee avec Flutter. L'objectif est d'aider l'utilisateur a mieux preparer ses courses.

L'idee principale du projet, ce n'est pas de partir d'un ticket de caisse, mais vraiment de partir de la liste de courses. L'utilisateur peut creer ou importer une liste, puis l'application l'aide a comprendre ce qu'il y a dedans, a avoir un bilan global et a trouver des idees de recettes.

---

## Slide 2 - Le besoin utilisateur

**A afficher :**
- Faire ses courses plus simplement
- Mieux visualiser sa liste
- Trouver des recettes avec ses produits
- Avoir une vision nutritionnelle globale

**Ce que je dis :**

Le besoin auquel on voulait repondre est assez simple. Quand on fait ses courses, on a souvent une liste, mais elle reste juste une suite de produits.

Avec Komi, on voulait rendre cette liste plus utile. L'application permet de centraliser les produits, de les identifier comme aliments, d'avoir un bilan nutritionnel global, et ensuite de proposer une partie recettes pour aider l'utilisateur a cuisiner avec son univers alimentaire.

L'objectif n'etait pas de faire une application trop complexe, mais plutot un MVP clair, avec un parcours facile a comprendre.

---

## Slide 3 - Le parcours dans l'application

**A afficher :**
1. Connexion ou inscription
2. Accueil
3. Liste de courses
4. Recettes
5. Favoris et profil

**Ce que je dis :**

Le parcours utilisateur commence par l'inscription ou la connexion. Une fois connecte, l'utilisateur arrive dans l'application principale.

On a organise l'application avec une navigation en cinq parties : l'accueil, les recettes, la liste de courses, les favoris et le profil.

La partie centrale du projet est la liste de courses. L'utilisateur peut ajouter des aliments manuellement, ou importer une image depuis sa camera ou sa galerie. Ensuite, les elements reconnus peuvent etre exploites par l'application pour construire le bilan des courses.

La partie recettes permet de rechercher des idees, de consulter le detail d'une recette et de l'ajouter en favoris.

---

## Slide 4 - Ma partie cote Flutter

**A afficher :**
- Interface mobile
- Navigation principale
- Ecrans : home, liste, recettes, favoris, profil
- Gestion de l'etat avec Provider

**Ce que je dis :**

Sur ma partie, je peux surtout parler du front Flutter et de l'experience utilisateur.

Flutter nous a permis de construire une application mobile tout en pouvant la tester aussi sur le web pendant le developpement. On a decoupe le projet par fonctionnalites : l'authentification, l'accueil, la liste de courses, le profil, les recettes et les favoris.

Pour la gestion de l'etat, on utilise Provider. Par exemple, il y a un provider pour la session utilisateur, un provider pour la liste de courses, et un provider pour les favoris.

Ce choix reste simple, mais il est adapte a notre MVP. Il permet aux ecrans de se mettre a jour quand l'utilisateur ajoute un produit ou sauvegarde une recette.

---

## Slide 5 - Les fonctionnalites visibles

**A afficher :**
- Creation de compte et connexion
- Session locale
- Ajout manuel d'aliments
- Import image camera / galerie
- Bilan des courses
- Recherche de recettes
- Favoris
- Profil et abonnement

**Ce que je dis :**

Aujourd'hui, plusieurs fonctionnalites sont deja visibles dans l'application.

L'utilisateur peut creer un compte, se connecter et garder une session locale pendant une certaine duree. Il peut ensuite gerer sa liste de courses, ajouter des aliments manuellement, ou importer une image.

On a aussi une partie bilan des courses, qui donne une vision globale de la liste. A cote de ca, l'utilisateur peut rechercher des recettes grace a TheMealDB, ouvrir le detail d'une recette et l'ajouter dans ses favoris.

Enfin, il y a une page profil avec les informations utilisateur et une partie abonnement, notamment pour le passage vers une offre Premium.

---

## Slide 6 - Choix d'organisation du code

**A afficher :**
- Code range par fonctionnalite
- Providers pour l'etat local
- Services pour les appels API
- Modeles pour structurer les donnees

**Ce que je dis :**

On a essaye de garder une organisation de code assez lisible.

Dans le dossier `lib`, les fichiers sont ranges par grandes fonctionnalites. Les ecrans lies a l'authentification sont ensemble, ceux de la liste de courses aussi, pareil pour le profil et l'accueil.

Les providers servent a gerer les donnees qui changent dans l'application. Les services servent plutot aux appels vers le backend ou vers des API externes, comme TheMealDB.

Cette organisation nous permet de separer l'interface, la logique d'etat et les appels reseau. C'est plus simple a maintenir et plus facile a expliquer dans un projet de groupe.

---

## Slide 7 - Ce qui est encore a ameliorer

**A afficher :**
- Suggestions de menus plus personnalisees
- Synchronisation complete des favoris
- Paiement Premium a finaliser
- Historique utilisateur
- Bilan nutritionnel plus precis

**Ce que je dis :**

Comme c'est un MVP, certaines parties sont encore partielles.

Par exemple, les suggestions de menus ne sont pas encore totalement personnalisees a partir de la vraie liste de courses. Les favoris sont sauvegardes localement, donc ils ne sont pas encore synchronises entre plusieurs appareils.

Le paiement Stripe peut ouvrir une session Checkout, mais il manque encore la partie webhook pour activer automatiquement le Premium apres paiement.

On pourrait aussi ameliorer l'historique utilisateur et rendre le bilan nutritionnel plus precis avec une base de donnees alimentaire plus complete.

---

## Slide 8 - Conclusion

**A afficher :**
- MVP fonctionnel
- Parcours utilisateur clair
- Base front solide
- Evolutions possibles

**Ce que je dis :**

Pour conclure, Komi est aujourd'hui un MVP fonctionnel autour de la liste de courses.

La partie front permet deja a l'utilisateur de se connecter, de naviguer dans l'application, de gerer sa liste, de consulter un bilan, de rechercher des recettes et d'enregistrer des favoris.

Le projet a encore des ameliorations possibles, mais la base est deja en place. Les prochaines evolutions seraient surtout de rendre les recommandations plus intelligentes, de synchroniser davantage les donnees avec le backend et de finaliser toute la logique Premium.

Je vais maintenant laisser la parole a mon binome, qui va presenter plus en detail la partie backend, l'architecture API et les traitements cote serveur.
