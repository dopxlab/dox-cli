FROM alpine:3.22

# Install glibc (required for GraalVM native images)
RUN apk add --no-cache glibc

# Create non-root user for security
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -s /bin/sh -D appuser

# Copy the native executable
COPY target/graalvm_app /graalvm_app
RUN chmod +x /graalvm_app
RUN chown appuser:appgroup /graalvm_app

USER appuser

# Set entrypoint with memory configuration
ENTRYPOINT ["/graalvm_app"]