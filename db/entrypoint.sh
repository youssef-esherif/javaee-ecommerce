#!/bin/bash
set -e

SQLCMD_BIN=/opt/mssql-tools18/bin/sqlcmd
DB_NAME="ecommerce_db"
MIGRATIONS_DIR="/migrations"

SQLCMD_ARGS=(-S db -U sa -P "$MSSQL_SA_PASSWORD" -C -N -b)

sqlcmd_run() {
    "$SQLCMD_BIN" "${SQLCMD_ARGS[@]}" "$@"
}

echo "Waiting for SQL Server to accept connections..."
until sqlcmd_run -Q "SELECT 1" > /dev/null 2>&1; do
    sleep 2
done
echo "SQL Server is up."

echo "Ensuring database [$DB_NAME] exists..."
sqlcmd_run -Q "IF DB_ID('$DB_NAME') IS NULL CREATE DATABASE [$DB_NAME];"

echo "Ensuring schema_migrations tracking table exists..."
sqlcmd_run -d "$DB_NAME" -Q "
IF OBJECT_ID('dbo.schema_migrations') IS NULL
CREATE TABLE dbo.schema_migrations (
    filename NVARCHAR(255) PRIMARY KEY,
    applied_at DATETIME2 DEFAULT SYSUTCDATETIME()
);"

shopt -s nullglob
files=("$MIGRATIONS_DIR"/*.sql)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "No migration files found in $MIGRATIONS_DIR."
    exit 0
fi

IFS=$'\n' sorted=($(sort <<<"${files[*]}")); unset IFS

for f in "${sorted[@]}"; do
    name=$(basename "$f")

    already=$(sqlcmd_run -d "$DB_NAME" -h -1 -W -Q \
        "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.schema_migrations WHERE filename = '$name';" \
        | tr -d '[:space:]')

    if [ "$already" = "0" ]; then
        echo "Applying migration: $name"
        sqlcmd_run -d "$DB_NAME" -i "$f"
        sqlcmd_run -d "$DB_NAME" -Q \
            "INSERT INTO dbo.schema_migrations (filename) VALUES ('$name');"
    else
        echo "Skipping $name (already applied)"
    fi
done

echo "All migrations applied."
