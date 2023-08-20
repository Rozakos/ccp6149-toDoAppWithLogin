# Use an official OpenJDK runtime as a parent image
FROM openjdk:11-jre-slim

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the JAR file from your build context to the container's working directory
COPY first_job/target/ToDoAppWithLogin.jar ./app.jar

# Specify the port number the container should expose
EXPOSE 8080

# Run the application when the container launches
ENTRYPOINT ["java", "-jar", "./app.jar"]
