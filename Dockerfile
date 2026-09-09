# =========================
# Stage 1: Build
# =========================
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /app

# Copy dependencies
COPY libs ./libs
COPY web/WEB-INF/lib ./web/WEB-INF/lib

# Copy source code and web files
COPY src ./src
COPY web ./web

# Compile
RUN mkdir -p web/WEB-INF/classes && \
    javac -encoding UTF-8 \
    -cp "libs/*:web/WEB-INF/lib/*" \
    -d web/WEB-INF/classes \
    $(find src -name "*.java")

# Build WAR
RUN rm -f javaee-ecommerce.war && \
    cd web && \
    jar -cvf ../javaee-ecommerce.war *


# =========================
# Stage 2: Run
# =========================
FROM tomcat:10.1.36-jdk21-temurin

RUN rm -rf /usr/local/tomcat/webapps/ROOT

COPY --from=builder /app/javaee-ecommerce.war \
    /usr/local/tomcat/webapps/javaee-ecommerce.war

EXPOSE 8080

CMD ["catalina.sh", "run"]