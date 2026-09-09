#!/bin/bash
# Compiles the servlet sources and packages web/ into a deployable WAR.
# No Maven involved — just javac + jar.

set -e

APP_NAME=javaee-ecommerce

if [ -z "$(ls -A libs 2>/dev/null)" ]; then
  echo "ERROR: libs/ is empty. Download the servlet-api jar first."
  exit 1
fi

if [ -z "$(ls -A web/WEB-INF/lib 2>/dev/null)" ]; then
  echo "ERROR: web/WEB-INF/lib is empty. Download the PostgreSQL JDBC driver first."
  exit 1
fi

echo "Compiling sources..."

mkdir -p web/WEB-INF/classes

javac -encoding UTF-8 \
  -cp "libs/*;web/WEB-INF/lib/*" \
  -d web/WEB-INF/classes \
  $(find src -name "*.java")

echo "Packaging WAR..."

rm -f "${APP_NAME}.war"

(cd web && jar -cvf "../${APP_NAME}.war" *)

echo ""
echo "Built ${APP_NAME}.war"