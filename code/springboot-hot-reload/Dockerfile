FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn package -DskipTests -q

FROM eclipse-temurin:21-jre-alpine

# OCI Labels
LABEL org.opencontainers.image.title="Spring Boot Conjur Hot-Reload Demo"
LABEL org.opencontainers.image.authors="Assaf Hazan"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="Spring Boot application demonstrating zero-restart database credential hot-reload using Conjur push-to-file mechanism"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
