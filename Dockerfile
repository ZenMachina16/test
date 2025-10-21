# This Dockerfile sets up a multi-stage build for a production-ready Node.js application.
# Multi-stage builds help create smaller, more secure production images by separating
# build-time dependencies from runtime dependencies.

# --- Stage 1: Builder ---
# This stage installs Node.js dependencies and performs any build-related tasks.
# We use a recent LTS version of Node.js on an Alpine base for a smaller image footprint.
FROM node:20-alpine AS builder

# Set the working directory inside the container for all subsequent commands.
WORKDIR /app

# Copy the package.json and package-lock.json files first.
# This allows Docker to cache the dependency installation step. If these files
# don't change, Docker can use the cached layer, speeding up subsequent builds.
COPY package.json ./
# It's crucial to have a package-lock.json for consistent dependency installs in production.
# If you use Yarn, copy yarn.lock instead: COPY yarn.lock ./
COPY package-lock.json ./

# Install only production dependencies.
# 'npm ci' is preferred over 'npm install' in CI/CD and production environments
# because it uses package-lock.json exclusively, ensuring consistent installs.
# '--omit=dev' prevents installation of development dependencies, further reducing image size.
RUN npm ci --omit=dev

# If your application has a build step (e.g., transpiling TypeScript, bundling frontend assets),
# uncomment and add those commands here. For a simple 'node index.js' app, this is often not needed.
# Example:
# COPY . .
# RUN npm run build

# --- Stage 2: Production ---
# This stage creates the final, minimal image containing only the application and its runtime dependencies.
# We reuse the same Node.js LTS Alpine base image for consistency and size.
FROM node:20-alpine

# Set the working directory inside the container.
WORKDIR /app

# Set environment variables for the production environment.
# This helps optimize Node.js performance and error reporting.
ENV NODE_ENV=production

# Copy only the installed production node_modules from the 'builder' stage.
# This dramatically reduces the final image size and avoids copying build-time tools.
COPY --from=builder /app/node_modules ./node_modules

# Copy the rest of the application source code.
# Ensure you have a .dockerignore file in your project root to exclude unnecessary files
# (e.g., node_modules, .git, .env files, build artifacts) from being copied into the image.
# A typical .dockerignore might include:
# node_modules
# npm-debug.log
# .git
# .env
# .vscode
# Dockerfile
# README.md
COPY . .

# Expose the port your application listens on.
# The common default port for Node.js applications is 3000.
# Adjust this if your application listens on a different port.
EXPOSE 3000

# Set the user to 'node' for security best practices.
# Running as a non-root user mitigates potential security vulnerabilities.
# The 'node:alpine' base images typically include a 'node' user with appropriate permissions.
USER node

# Define the command to run the application when the container starts.
# This uses the 'start' script defined in your package.json, which is specified as "node index.js".
CMD ["npm", "start"]