FROM ##FROM_IMAGE##

# Set working directory
WORKDIR /app

# Copy the built JAR file
COPY target/*.jar app.jar

# Default command
ENTRYPOINT ["java", "-jar", "app.jar"]
