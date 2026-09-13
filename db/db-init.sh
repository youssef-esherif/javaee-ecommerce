#!/bin/bash

set -e

SERVER="db"
USER="sa"
DATABASE="ecommerce_db"

echo "Waiting for SQL Server..."

until /opt/mssql-tools18/bin/sqlcmd \
    -S "$SERVER" \
    -U "$USER" \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -Q "SELECT 1" \
    -b \
    -o /dev/null
do
    echo "SQL Server is not ready yet..."
    sleep 2
done

echo "SQL Server is ready."

echo "Waiting for SQL Server login to become available..."

until /opt/mssql-tools18/bin/sqlcmd \
    -S "$SERVER" \
    -U "$USER" \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -d master \
    -Q "SELECT 1" \
    -b \
    -o /dev/null
do
    echo "SQL Server login is not ready yet..."
    sleep 2
done

echo "SQL Server login is ready."

echo "Creating database if it does not exist..."

/opt/mssql-tools18/bin/sqlcmd \
    -S "$SERVER" \
    -U "$USER" \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -d master \
    -Q "IF DB_ID('$DATABASE') IS NULL CREATE DATABASE [$DATABASE]" \
    -b

echo "Database is ready."

echo "Waiting for database $DATABASE to become ONLINE..."

while true
do
    state=$(
        /opt/mssql-tools18/bin/sqlcmd \
            -S "$SERVER" \
            -U "$USER" \
            -P "$MSSQL_SA_PASSWORD" \
            -C \
            -d master \
            -h -1 \
            -W \
            -Q "SET NOCOUNT ON;
                SELECT state_desc
                FROM sys.databases
                WHERE name = '$DATABASE';" \
            -b 2>/dev/null |
        tr -d '[:space:]'
    )

    if [ "$state" = "ONLINE" ]; then
        break
    fi

    echo "Database state: ${state:-NOT_FOUND}. Waiting..."
    sleep 2
done

echo "Database $DATABASE is ONLINE."

echo "Creating migration tracking table..."

/opt/mssql-tools18/bin/sqlcmd \
    -S "$SERVER" \
    -U "$USER" \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -d "$DATABASE" \
    -Q "
        IF OBJECT_ID('schema_migrations', 'U') IS NULL
        BEGIN
            CREATE TABLE schema_migrations (
                version VARCHAR(50) PRIMARY KEY,
                filename VARCHAR(255) NOT NULL,
                applied_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
            );
        END
    " \
    -b

echo "Checking migrations..."

for file in /migrations/V*.sql
do
    [ -e "$file" ] || continue

    filename=$(basename "$file")
    version=$(echo "$filename" | cut -d'_' -f1)

    echo "Checking migration: $filename"

    applied=$(
        /opt/mssql-tools18/bin/sqlcmd \
            -S "$SERVER" \
            -U "$USER" \
            -P "$MSSQL_SA_PASSWORD" \
            -C \
            -d "$DATABASE" \
            -h -1 \
            -W \
            -Q "SET NOCOUNT ON;
                IF EXISTS (
                    SELECT 1
                    FROM schema_migrations
                    WHERE version = '$version'
                )
                    SELECT 1
                ELSE
                    SELECT 0" \
            -b
    )

    applied=$(echo "$applied" | tr -d '[:space:]')

    if [ "$applied" = "1" ]; then
        echo "Already applied: $filename"
        continue
    fi

    echo "Applying migration: $filename"

    /opt/mssql-tools18/bin/sqlcmd \
        -S "$SERVER" \
        -U "$USER" \
        -P "$MSSQL_SA_PASSWORD" \
        -C \
        -d "$DATABASE" \
        -i "$file" \
        -b

    echo "Recording migration: $filename"

    /opt/mssql-tools18/bin/sqlcmd \
        -S "$SERVER" \
        -U "$USER" \
        -P "$MSSQL_SA_PASSWORD" \
        -C \
        -d "$DATABASE" \
        -Q "INSERT INTO schema_migrations (version, filename)
            VALUES ('$version', '$filename')" \
        -b

    echo "Migration completed: $filename"
done

echo "All migrations completed successfully."