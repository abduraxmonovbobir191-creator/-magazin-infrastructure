# Magazin Infrastructure

PostgreSQL schema and local Docker setup for Magazin POS/accounting.

## Start database
1. Copy `.env.example` to `.env`.
2. Set a strong unique `POSTGRES_PASSWORD`.
3. Run `docker compose up -d`.
4. Check: `docker compose ps` and `docker compose logs postgres`.

Schema is initialized automatically only for a brand-new empty PostgreSQL volume. For an existing database, apply schema changes through reviewed migrations rather than deleting the volume.

## Backend connection
`DATABASE_URL=postgresql://magazin:<password>@localhost:5432/magazin`

For remote production use, do not expose PostgreSQL port publicly. Configure firewall rules, TLS, restricted DB roles, encrypted backups, and periodically test restore.

## Security
Never commit real `.env` files, passwords, production dumps, customer data, or bot tokens.
