FROM openjdk:11-jre-slim

WORKDIR /usr/src/app

COPY /var/lib/jenkins/workspace/first_job/target/toDoAppWithLogin.jar ./app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
