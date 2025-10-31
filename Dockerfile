Of course. As a DevOps expert, I will generate a complete and production-ready Dockerfile for your JavaScript application.

This Dockerfile incorporates best practices for security, efficiency, and reproducibility, including:
*   **Multi-stage builds** to create a small, secure final image.
*   **Dependency caching** to speed up subsequent builds.
*   **Running as a non-root user** to enhance security.
*   **Graceful shutdown handling** for container orchestration.
*   **Specific Node.js versioning** for predictable builds.

Here is the generated `Dockerfile`:

```dockerfile
# =========================================================================
# Stage 1: Builder
#
# This stage installs dependencies and builds the application. It uses a full
# Node.js image that includes build tools. The resulting artifacts will be
# copied to the final, smaller production stage.
#
# Note: It is highly recommended to create a .dockerignore file in your
# project root to exclude files like .git, node_modules, and .env from the
# Docker build context.
# Example .dockerignore:
# node_modules
# .git
# .env
# Dockerfile
# README.md
# =========================================================================
FROM node:20-alpine AS builder

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if available)
# This leverages Docker's layer caching. This layer is only rebuilt when
# these files change.
COPY package*.json ./

# Install production dependencies using 'npm ci'
# 'npm ci' is faster and more reliable for builds than 'npm install' as it
# uses the package-lock.json file to ensure deterministic builds.
# The --only=production flag ensures that devDependencies are not installed.
RUN npm ci --only=production

# Copy the rest of the application source code
COPY . .

# =========================================================================
# Stage 2: Production
#
# This stage creates the final, lean production image. It starts from a
# clean, minimal Node.js base and copies only the necessary application
# code and dependencies from the 'builder' stage.
# =========================================================================
FROM node:20-alpine

# Set the environment to 'production'
# This optimizes Node.js and certain libraries for performance and security.
ENV NODE_ENV=production

# Set the working directory
WORKDIR /usr/src/app

# Create a dedicated, unprivileged user and group for the application
# Running as a non-root user is a critical security best practice.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy installed dependencies from the 'builder' stage
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Copy application code from the 'builder' stage
COPY --from=builder /usr/src/app .

# Change ownership of the application files to the non-root user
RUN chown -R appuser:appgroup .

# Switch to the non-root user
USER appuser

# Expose the port the application will run on.
# IMPORTANT: This is for documentation purposes. You must map this port when
# running the container (e.g., `docker run -p 3000:3000 <image>`).
# Please change '3000' to the actual port your application uses.
EXPOSE 3000

# The command to start the application.
# Using 'node index.js' directly is more robust than 'npm start' for signal
# handling (e.g., CTRL+C or docker stop), allowing for graceful shutdowns.
CMD ["node", "index.js"]
```