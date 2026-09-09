# javaee-ecommerce

A plain Java EE Servlet project — **no Maven, no build tool**. Dependencies
are plain `.jar` files, compiled with `javac`, packaged into a WAR with
`jar`, and deployed to Apache Tomcat. Runs either directly on
**Apache Tomcat 10.1.36**, or in Docker alongside PostgreSQL.

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
│       └── lib/                # RUNTIME jars shipped inside the WAR (e.g. postgresql driver)
├── libs/                      # COMPILE-TIME-ONLY jars (e.g. servlet-api) — never shipped in the WAR
├── build.sh                   # compiles + packages the WAR
├── Dockerfile                 # tomcat:10.1.36-jdk21-temurin
├── docker-compose.yml         # app + postgres
└── .gitignore
```

Why two separate jar folders: `libs/` holds the **Jakarta Servlet API**
jar, which you only need so `javac` can compile against
`jakarta.servlet.*` classes — Tomcat already provides that API at
runtime, so bundling it too would cause classpath conflicts.
`web/WEB-INF/lib/` holds jars Tomcat does **not** provide, like the
PostgreSQL JDBC driver, so those must ship inside the WAR.

## Prerequisites

- JDK 21 (to match `apache-tomcat-10.1.36`, which requires Java 17+)
- `curl` (to download the two dependency jars)
- Either:
  - **Docker + Docker Compose**, or
  - A local install of **Apache Tomcat 10.1.36** and a local **PostgreSQL** instance



Confirm both landed:

```bash
ls libs/                # jakarta.servlet-api-6.0.0.jar
ls web/WEB-INF/lib/     # postgresql-42.7.4.jar
```

## Step 1 — Build the WAR

```bash
chmod +x build.sh
./build.sh
```

This compiles everything in `src/` against `libs/*` and
`web/WEB-INF/lib/*`, drops the `.class` files into
`web/WEB-INF/classes/`, then zips the whole `web/` folder into
`javaee-ecommerce.war` in the project root.

## Step 2A — Run with Docker (recommended)

```bash
docker compose up --build
```

This starts two containers:
- `ecommerce-db` — PostgreSQL 16, database `ecommerce_db`, user/pass `ecommerce` / `ecommerce_pass`
- `ecommerce-app` — Tomcat 10.1.36 with `javaee-ecommerce.war` deployed, waiting for the DB healthcheck before starting

Once it's up, visit:
- `http://localhost:8080/javaee-ecommerce/` — welcome page
- `http://localhost:8080/javaee-ecommerce/hello` — plain servlet check
- `http://localhost:8080/javaee-ecommerce/db-test` — confirms the app can reach PostgreSQL

Stop everything with:

```bash
docker compose down          # stop containers, keep DB data
docker compose down -v       # stop containers AND wipe the DB volume
```

Whenever you change Java code, re-run `./build.sh` then
`docker compose up --build` again (only `app` needs rebuilding, but
`--build` is harmless for `db` too since it's a bare image).

## Step 2B — Run without Docker, on local Apache Tomcat 10.1.36

1. Install/unpack `apache-tomcat-10.1.36` and have a local PostgreSQL
   running with a database, user, and password of your choice.

2. Export the connection details as environment variables before
   starting Tomcat (adjust to your local DB):

   ```bash
   export DB_URL="jdbc:postgresql://localhost:5432/ecommerce_db"
   export DB_USER="ecommerce"
   export DB_PASSWORD="ecommerce_pass"
   ```

   Tomcat inherits environment variables from the shell that launches
   it, so run `catalina.sh` from that same shell (or add these lines
   to `apache-tomcat-10.1.36/bin/setenv.sh`, creating the file if it
   doesn't exist, so they're set automatically every time).

3. Build the WAR (Step 2 above), then deploy it:

   ```bash
   cp javaee-ecommerce.war $CATALINA_HOME/webapps/
   $CATALINA_HOME/bin/catalina.sh run
   ```

4. Visit the same URLs as in Step 3A.

## Troubleshooting

- **`ClassNotFoundException: jakarta.servlet...` during compile** — the
  jar didn't download correctly into `libs/`; re-run the `curl` command
  from Step 1 and check the file size isn't 0 bytes.
- **`db-test` returns "DB connection failed"** — check `DB_URL` /
  `DB_USER` / `DB_PASSWORD` are actually set in the environment Tomcat
  is running in (in Docker they come from `docker-compose.yml`; locally
  from your shell/`setenv.sh`).
- **`docker compose up` fails to pull `tomcat:10.1.36-jdk21-temurin`** —
  check available tags at hub.docker.com/_/tomcat/tags and swap the tag
  in `Dockerfile` for the closest match to your JDK (e.g.
  `10.1.36-jdk17-temurin`).
- **Changed a `.java` file but nothing changed at runtime** — you must
  re-run `./build.sh` and redeploy the WAR; there's no hot-reload
  without a build tool watching your files.
