# javaee-ecommerce

A plain Java EE Servlet project — **no Maven, no build tool**. Dependencies
are plain `.jar` files, compiled with `javac`, packaged into a WAR with
`jar`, and deployed to Apache Tomcat. Runs on **Apache Tomcat 10.1.36**
against **SQL Server**, either directly or in Docker.

## Project layout

```
javaee-ecommerce/
├── src/                       # Java sources
│   └── com/ecommerce/
│       ├── servlet/           # HelloServlet, DbTestServlet
│       └── dao/                # DbConnection (JDBC helper)
├── web/                       # becomes the WAR root
│   ├── index.jsp
│   └── WEB-INF/
│       ├── web.xml
│       ├── classes/           # compiled .class files land here (generated)
│       └── lib/                # RUNTIME jars shipped inside the WAR (mssql-jdbc)
├── libs/                      # COMPILE-TIME-ONLY jars (servlet-api) — never shipped in the WAR
├── build.sh                   # runs `docker compose up --build`
├── Dockerfile                 # multi-stage: compiles inside Docker, then tomcat:10.1.36-jdk21-temurin
├── docker-compose.yml         # app + SQL Server + one-shot db-init
└── .gitignore
```

Why two separate jar folders: `libs/` holds the **Jakarta Servlet API**
jar, needed only so `javac` can compile against `jakarta.servlet.*`
classes — Tomcat already provides that API at runtime, so bundling it
too would cause classpath conflicts. `web/WEB-INF/lib/` holds jars
Tomcat does **not** provide, like the SQL Server JDBC driver, so those
must ship inside the WAR.

## Prerequisites

- Docker + Docker Compose (the whole build now happens inside Docker — see `Dockerfile`)
- `curl` (to download the two dependency jars, once, before the first build)
- (Optional, for running outside Docker) JDK 21 and a local SQL Server instance

## Step 1 — Download the two dependency jars

These are plain jar downloads — no Maven required. Do this once, before
the first build; the files then live on disk and get baked into the
image every time you rebuild.

```bash
cd javaee-ecommerce

# Compile-time only: Jakarta Servlet API (matches Tomcat 10.1.x, Jakarta EE 10)
curl -L -o libs/jakarta.servlet-api-6.0.0.jar \
  https://repo1.maven.org/maven2/jakarta/servlet/jakarta.servlet-api/6.0.0/jakarta.servlet-api-6.0.0.jar

# Runtime, ships in the WAR: Microsoft JDBC driver for SQL Server
curl -L -o web/WEB-INF/lib/mssql-jdbc-12.10.2.jre11.jar \
  https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/12.10.2.jre11/mssql-jdbc-12.10.2.jre11.jar
```

Confirm both landed (and aren't 0 bytes):

```bash
ls -la libs/                # jakarta.servlet-api-6.0.0.jar
ls -la web/WEB-INF/lib/     # mssql-jdbc-12.10.2.jre11.jar
```

## Step 2 — Build and run

```bash
./build.sh
```

That runs `docker compose up --build`, which:
1. **Builds the app image** — the `Dockerfile`'s first stage compiles
   `src/` with `javac` (against `libs/*` and `web/WEB-INF/lib/*`) and
   packages `web/` into `javaee-ecommerce.war`; the second stage copies
   that WAR into a `tomcat:10.1.36-jdk21-temurin` image.
2. **Starts `db`** — SQL Server 2022, with a healthcheck that waits
   until `sqlcmd` can actually connect.
3. **Runs `db-init`** — a one-shot container that creates the
   `ecommerce_db` database once `db` is healthy (SQL Server, unlike
   Postgres, doesn't auto-create a database from an env var), then exits.
4. **Starts `app`** — waits for `db-init` to finish successfully, then
   boots Tomcat with the WAR deployed.

Once it's up, visit:
- `http://localhost:8080/javaee-ecommerce/` — welcome page
- `http://localhost:8080/javaee-ecommerce/hello` — plain servlet check
- `http://localhost:8080/javaee-ecommerce/db-test` — confirms the app can reach SQL Server

Stop everything with:

```bash
docker compose down          # stop containers, keep DB data
docker compose down -v       # stop containers AND wipe the DB volume
```

Whenever you change Java code, just re-run `./build.sh` — the compile
step happens inside the Docker build, so there's nothing to build on
the host first.

## Connection details (dev defaults)

Set in `docker-compose.yml` — change them before you put this anywhere
other than your own machine:

| Variable | Value |
|---|---|
| `DB_URL` | `jdbc:sqlserver://db:1433;databaseName=ecommerce_db;encrypt=true;trustServerCertificate=true` |
| `DB_USER` | `sa` |
| `DB_PASSWORD` / `MSSQL_SA_PASSWORD` | `Ecommerce_Pass1!` |

SQL Server enforces password complexity (8+ characters, at least three
of: uppercase, lowercase, digit, symbol) — keep that in mind if you
change it.

## Running without Docker, on local Apache Tomcat 10.1.36

1. Install/unpack `apache-tomcat-10.1.36` and have a local SQL Server
   instance running, with a database created (e.g. via SSMS or
   `sqlcmd -Q "CREATE DATABASE ecommerce_db"`).

2. Export the connection details before starting Tomcat (adjust host/DB/user):

   ```bash
   export DB_URL="jdbc:sqlserver://localhost:1433;databaseName=ecommerce_db;encrypt=true;trustServerCertificate=true"
   export DB_USER="sa"
   export DB_PASSWORD="Ecommerce_Pass1!"
   ```

   Tomcat inherits environment variables from the shell that launches
   it, so run `catalina.sh` from that same shell (or set these in
   `apache-tomcat-10.1.36/bin/setenv.sh`, creating it if it doesn't exist).

3. Compile and package manually (same commands the Dockerfile's build
   stage runs):

   ```bash
   mkdir -p web/WEB-INF/classes
   javac -encoding UTF-8 -cp "libs/*:web/WEB-INF/lib/*" \
     -d web/WEB-INF/classes $(find src -name "*.java")
   (cd web && jar -cvf ../javaee-ecommerce.war *)
   ```

4. Deploy and run:

   ```bash
   cp javaee-ecommerce.war $CATALINA_HOME/webapps/
   $CATALINA_HOME/bin/catalina.sh run
   ```

5. Visit the same URLs as in Step 2.

## Troubleshooting

- **`ClassNotFoundException: jakarta.servlet...` during the Docker
  build** — the jar didn't download correctly into `libs/`; re-run the
  `curl` command from Step 1 and check the file size isn't 0 bytes.
- **`db-test` returns "DB connection failed"** — check `DB_URL` /
  `DB_USER` / `DB_PASSWORD` are set correctly, and that `db-init`
  actually completed (`docker compose logs db-init`).
- **`db-init` fails / `sqlcmd: command not found`** — the tools path
  moved to `/opt/mssql-tools18/bin/sqlcmd` in current SQL Server
  images; if Microsoft changes it again, check
  `docker exec -it ecommerce-db find / -name sqlcmd` and update the
  path in `docker-compose.yml`.
- **`docker compose up` fails to pull `tomcat:10.1.36-jdk21-temurin`**
  — check available tags at hub.docker.com/_/tomcat/tags and swap the
  tag in `Dockerfile` for the closest match to your JDK.
- **Login fails with "password validation failed"** — SQL Server
  rejected `MSSQL_SA_PASSWORD` for not meeting complexity rules; use a
  password with upper+lower+digit+symbol, 8+ characters.
