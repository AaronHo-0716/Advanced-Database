#!/usr/bin/env bash
set -euo pipefail

# load .env
if [ -f .env ]; then
  set -a; . ./.env; set +a
else
  echo "ERROR: .env not found. Copy .env.example to .env first."; exit 1
fi

SA_PASS="${MSSQL_SA_PASSWORD}"
DB="${DB_NAME:-glcl}"

# detect sqlcmd path inside the container (image versions differ)
detect_sqlcmd() {
  if docker exec glcl-mssql test -x /opt/mssql-tools18/bin/sqlcmd 2>/dev/null; then
    echo "/opt/mssql-tools18/bin/sqlcmd"
  elif docker exec glcl-mssql test -x /opt/mssql-tools/bin/sqlcmd 2>/dev/null; then
    echo "/opt/mssql-tools/bin/sqlcmd"
  else
    echo ""
  fi
}

echo ">> tearing down (wiping volume for clean state)"
docker compose down -v

echo ">> starting SQL Server"
docker compose up -d

echo ">> resolving sqlcmd path inside container"
SQLCMD=""
until [ -n "$SQLCMD" ]; do
  SQLCMD="$(detect_sqlcmd)"
  [ -z "$SQLCMD" ] && { printf "."; sleep 2; }
done
echo " using $SQLCMD"

echo ">> waiting for SQL Server to accept connections"
until docker exec glcl-mssql "$SQLCMD" -S localhost -U sa -P "$SA_PASS" -C -Q "SELECT 1" >/dev/null 2>&1; do
  printf "."; sleep 2
done
echo " ready."

echo ">> creating database $DB"
docker exec glcl-mssql "$SQLCMD" -S localhost -U sa -P "$SA_PASS" -C \
  -Q "IF DB_ID('$DB') IS NULL CREATE DATABASE [$DB];"

echo ">> applying schema scripts"
for f in schema/*.sql; do
  echo "   applying $f"
  docker exec -i glcl-mssql "$SQLCMD" -S localhost -U sa -P "$SA_PASS" -C -d "$DB" -i /dev/stdin < "$f"
done

echo ">> done. Database '$DB' is rebuilt and seeded."
