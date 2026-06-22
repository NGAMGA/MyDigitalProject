# Déploiement Komi sur un VPS

Architecture cible :

```text
https://YOUR_DOMAIN/       site vitrine
https://YOUR_DOMAIN/app/   application Flutter Web
https://YOUR_DOMAIN/api/   API FastAPI
```

## 1. Préparer les secrets

Copier `.env.production.example` vers `.env.production`, remplacer
`YOUR_DOMAIN` et toutes les valeurs `replace...`.

Ne jamais ajouter `.env.production` à Git.

## 2. Construire l'application

Depuis Windows :

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy\build-production.ps1 -Domain YOUR_DOMAIN
```

Le build est créé dans `build/web`.

## 3. Arborescence attendue sur le VPS

```text
/opt/komi/app-repo/              dépôt Flutter/FastAPI
/opt/komi/site-repo/             dépôt du site vitrine
/var/www/komi/public/            fichiers publics
/var/www/komi/public/app/        build Flutter
```

Copier le site vitrine dans `/var/www/komi/public`, puis le contenu de
`build/web` dans `/var/www/komi/public/app`.

## 4. Lancer la base et l'API

```bash
cd /opt/komi/app-repo/deploy
cp .env.production.example .env.production
nano .env.production
docker compose -f docker-compose.prod.yml up -d --build
```

PostgreSQL n'est pas exposé publiquement. FastAPI écoute seulement sur
`127.0.0.1:8000`.

## 5. Configurer Nginx

Copier `nginx-komi.conf.example` vers `/etc/nginx/sites-available/komi`,
remplacer `YOUR_DOMAIN`, puis :

```bash
sudo ln -s /etc/nginx/sites-available/komi /etc/nginx/sites-enabled/komi
sudo nginx -t
sudo systemctl reload nginx
```

## 6. Activer HTTPS

Avec Certbot :

```bash
sudo certbot --nginx -d YOUR_DOMAIN
```

## 7. Configurer Stripe

Créer le webhook :

```text
https://YOUR_DOMAIN/api/v1/subscription/webhook
```

Événements :

```text
checkout.session.completed
customer.subscription.created
customer.subscription.updated
customer.subscription.deleted
```

Placer le secret `whsec_...` obtenu dans `.env.production`, puis relancer :

```bash
docker compose -f docker-compose.prod.yml up -d
```
