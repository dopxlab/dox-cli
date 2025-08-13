# Start from a tiny base image
FROM alpine:3.20

WORKDIR /app

# Copy the native executable
COPY target/graalvm_app /app/graalvm_app

# Ensure execution permissions
RUN chmod +x /app/graalvm_app

# Set entrypoint
ENTRYPOINT ["/app/graalvm_app"]