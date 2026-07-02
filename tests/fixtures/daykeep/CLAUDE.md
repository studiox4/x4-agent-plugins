# Daykeep

A monorepo project for testing Claude Code plugins.

## Tech Stack

- Runtime: Bun
- Framework: Next.js (frontend), Hono (API)
- Database: PostgreSQL via Drizzle ORM
- Monorepo: Turborepo

## Structure

- `apps/web/` — Next.js frontend
- `apps/api/` — Hono API server
- `packages/database/` — Drizzle schema and migrations
- `packages/shared/` — Shared types and utilities
