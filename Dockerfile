# Pinned to match the Apache Tomcat 10.1.36 you're developing against.
FROM tomcat:10.1.36-jdk21-temurin

# Remove the default sample app so it doesn't sit next to ours
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# The WAR is built on the host first (./build.sh), then copied in here.
COPY javaee-ecommerce.war /usr/local/tomcat/webapps/javaee-ecommerce.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
