FROM adoptopenjdk/openjdk11:x86_64-alpine-jre-11.0.18_10
# OCI Labels
LABEL org.opencontainers.image.authors="assafjh"
LABEL org.opencontainers.image.source="https://github.com/assafjh/cybr-demos"
LABEL org.opencontainers.image.description="Spring Boot demo application for Conjur integration"
LABEL org.opencontainers.image.licenses="MIT"

RUN mkdir -p /etc/demo && chown -R 1000:1000 /etc/demo

COPY --chown=1000:1000 demo-0.0.1-SNAPSHOT.jar /etc/demo/

WORKDIR /etc/demo
USER 1000:1000
  
ENTRYPOINT [ "java", "-jar", "/etc/demo/demo-0.0.1-SNAPSHOT.jar" ]
