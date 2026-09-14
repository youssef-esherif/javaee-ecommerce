# Reuses the SQL Server image purely because it already ships sqlcmd
# at /opt/mssql-tools18/bin/sqlcmd - we never run the DB engine from here.
FROM mcr.microsoft.com/mssql/server:2022-latest

USER root
WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
