# Start from a tiny base image
FROM alpine:3.22

# Copy the native executable
COPY target/graalvm_app /graalvm_app

# Set entrypoint
ENTRYPOINT ["/graalvm_app"]