# Magazin Infrastructure

PostgreSQL schema, Docker Compose deployment, and operational notes for the Magazin grocery POS.

## Repositories expected side-by-side

Clone all three repositories into the same parent directory:

```bash
git clone https://github.com/abduraxmonovbobir191-creator/magazin-frontend.git
git clone https://github.com/abduraxmonovbobir191-creator/magazin-backend.git
git clone https://github.com/abduraxmonovbobir191-creator/-magazin-infrastructure.git
cd -magazin-infrastructure
```

## Start the stack

1. Copy `.env.example` to `.env`.
2. Set a unique strong `POSTGRES_PASSWORD` and a random `JWT_SECRET` of at least 32 characters.
3. Set `NEXT_PUBLIC_API_URL` and `CORS_ORIGIN` to the real HTTPS API/web addresses for production. Local defaults are for development only.
4. Start services:

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f backend
```

The database is bound to localhost only. Frontend and API are also bound to localhost; use a reverse proxy such as Nginx/Caddy with HTTPS for public access.

## Create the first owner

After the backend image is built and the database is healthy, run the one-time bootstrap from the backend repository/container using a unique username and a strong password. The bootstrap script refuses to overwrite an existing username.

For example, from the backend repository with a correctly configured private `.env` and database connection:

```bash
npm install
npm run seed:admin
```

Set `ADMIN_USERNAME` and `ADMIN_PASSWORD` in the private backend environment only for this one-time operation. Remove these bootstrap variables after the owner account is created. Never use a sample password in production.

## Database notes

- On a brand-new PostgreSQL volume, `db/schema.sql` initializes the schema automatically.
- For an existing database, apply reviewed migrations; do not delete the volume to force schema changes.
- Example backup: `docker compose exec -T postgres pg_dump -U magazin magazin > magazin-backup.sql`.
- Store backups outside the server and periodically test restoring them.

## Telegram bot

Create a bot with BotFather, then set `TELEGRAM_BOT_TOKEN` and the comma-separated administrator chat IDs in the private `.env`. The current bot supports `/today` and `/lowstock` for allowlisted chat IDs.

## Current MVP scope

- Responsive web/PWA, separate Flutter Android source
- API authentication and role checks
- Product catalogue and stock quantities
- Transactional sales with stock decrement, cost snapshot and credit sale
- Expenses, debts and partial debt payments
- Dashboard and Telegram read-only reports
- PostgreSQL schema and Docker Compose foundation

## Before real customer use

Complete end-to-end tests, role/branch access review, database migrations, backup-restore drill, rate limiting, monitoring, real fiskal/virtual cash-register integration, payment integrations, receipt printing, returns/cancellations, and accountant-approved profit/tax rules. The current MVP is not a certified fiscal cash register and must not be presented as one.
