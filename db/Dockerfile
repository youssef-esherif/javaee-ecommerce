FROM mcr.microsoft.com/mssql/server:2022-latest

COPY db-init.sh /db-init.sh

ENTRYPOINT ["/bin/bash", "/db-init.sh"]