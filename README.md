# GLCL Database

Group assignment for **Advanced Database Systems**: a reservation database for
**Global Luxury Cruise Lines (GLCL)**, a manager for multiple cruise operators.
Built on **MS SQL Server** (Developer edition) running in Docker. Graded scope:
**Cruise Reservations** and **Cruise Cancellations & Rescheduling**. Three
members; the database is rebuilt from scripts in this repo on every clone.

---

## Prerequisites

- **Docker Desktop** (Windows/macOS) or **Docker Engine + Compose v2** (Linux)
- **Git**
- Windows users: either **Git Bash** (to run `reset.sh`) or **PowerShell**
  (to run `reset.ps1`). Both work — pick one.
- A SQL GUI client. Recommended cross-platform options:
  - [Azure Data Studio](https://learn.microsoft.com/sql/azure-data-studio/) (free, Microsoft, Win/macOS/Linux)
  - [DBeaver Community](https://dbeaver.io/) (free, Win/macOS/Linux)
  - SSMS works too but is **Windows-only** and optional.

---

## First-time setup

```bash
git clone <repo-url> && cd Advanced-Database
cp .env.example .env        # edit the SA password if you want
./reset.sh                  # Linux / macOS / Git Bash
#   or:  .\reset.ps1        # Windows PowerShell
```

That's it. After `reset` finishes you have a running `glcl-mssql` container
listening on `localhost:1433` with the `glcl` database created and all schema
scripts applied.

---

## Daily workflow

```bash
git pull
./reset.sh
```

The database is **disposable**; the scripts are the truth. There is no
migration framework — every reset wipes the volume (`docker compose down -v`)
and replays `schema/*.sql` in filename order. That guarantees all three of us
test against the exact same state.

---

## Connecting a GUI client

| Field   | Value                          |
| ------- | ------------------------------ |
| Host    | `localhost`                    |
| Port    | `1433`                         |
| User    | `sa`                           |
| Password| value of `MSSQL_SA_PASSWORD` in your `.env` |
| Database| `glcl`                         |

**Tick "Trust server certificate"** in your client. The 2022 SQL Server image
uses a self-signed cert; without that box ticked, your client will refuse to
connect.

---

## How to make a schema change

1. Edit the relevant file under `schema/`.
2. Commit and push.
3. Tell the team to `git pull && ./reset.sh`.

**Coordinate before editing shared files:**

- `schema/01_create_tables.sql` — all tables and FKs (shared)
- `schema/02_constraints.sql` — shared CHECK constraints (shared)
- `schema/04_seed_data.sql` — test INSERTs (shared)

**Conflict-free files (own them; edit freely):**

- `schema/03a_member1_objects.sql`, `03b_member2_objects.sql`, `03c_member3_objects.sql`
- `members/member1/queries.sql`, `members/member2/queries.sql`, `members/member3/queries.sql`

---

## Resetting

`./reset.sh` (or `.\reset.ps1`) always returns the database to an identical
known-good state. Use it freely — it is the right tool for testing triggers,
proving an INSERT fails the way you expect, or recovering from "I broke the
DB while exploring."

---

## File ownership

| File                                  | Owner    |
| ------------------------------------- | -------- |
| `schema/01_create_tables.sql`         | shared   |
| `schema/02_constraints.sql`           | shared   |
| `schema/03a_member1_objects.sql`      | Member 1 |
| `schema/03b_member2_objects.sql`      | Member 2 |
| `schema/03c_member3_objects.sql`      | Member 3 |
| `schema/04_seed_data.sql`             | shared   |
| `members/member1/queries.sql`         | Member 1 (queries i–vii) |
| `members/member2/queries.sql`         | Member 2 (queries viii–xiv) |
| `members/member3/queries.sql`         | Member 3 (queries xv–xxi) |
| `docs/erd/Advanced_Database.drawio`   | shared (ERD) |
| `docs/reflections/`                   | each member's own file |

---

## Troubleshooting

- **Container exits seconds after start, no obvious error.** SA password
  failed the SQL Server complexity rules. It must be 8+ chars and contain
  uppercase, lowercase, digit, and a symbol. Fix `MSSQL_SA_PASSWORD` in
  `.env` and re-run `reset`.
- **`./reset.sh: bad interpreter` or `^M` errors.** Line endings got
  converted to CRLF somewhere. The committed `.gitattributes` forces LF for
  `.sh` and `.sql`, but if you somehow ended up with CRLF locally, run
  `dos2unix reset.sh` (or re-clone with `git config --global core.autocrlf false`).
- **TLS / certificate error from sqlcmd or your GUI client.** The 2022
  image's cert is self-signed. `reset.sh` already passes `-C` (trust cert);
  in your GUI client, tick "Trust server certificate."
- **`Login timeout expired` right after `docker compose up`.** SQL Server
  reports "container up" several seconds before it accepts connections.
  `reset.sh` polls for readiness and waits — don't try to apply scripts in
  parallel with `up -d`.

---

## Non-goals (intentional)

- No migration framework (Flyway/Liquibase/EF). Rebuild-from-scratch is the
  whole point: the data is disposable, the scripts are truth.
- The `.drawio` ERD is documentation, not the source of truth — `schema/*.sql`
  wins if they ever disagree.
- No MySQL/Postgres. The assignment requires T-SQL.
