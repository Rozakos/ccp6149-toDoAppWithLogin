FROM openjdk:11-jre-slim

WORKDIR /usr/src/app

COPY target/ToDoAppWithLogin.jar ./app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
