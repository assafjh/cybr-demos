FROM adoptopenjdk/openjdk11:x86_64-alpine-jre-11.0.18_10
LABEL maintainer=AssafHazan

RUN mkdir -p /etc/demo

COPY demo-0.0.1-SNAPSHOT.jar /etc/demo/

WORKDIR /etc/demo
  
ENTRYPOINT [ "java", "-jar", "/etc/demo/demo-0.0.1-SNAPSHOT.jar" ]
