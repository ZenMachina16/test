# Stage 1: Builder - Installs dependencies and prepares the application
FROM node:lts-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock) first.
# This allows Docker to cache the dependency installation step
# if these files haven't changed, speeding up subsequent builds.
COPY package*.json ./

# Install production dependencies.
# `npm ci` is preferred in CI/CD environments for deterministic builds
# as it installs exact versions from package-lock.json.
# `--only=production` ensures only production dependencies are installed,
# keeping the final image smaller.
# `npm cache clean --force` further reduces the image size by clearing the npm cache.
RUN npm ci --only=production && npm cache clean --force

# Copy the rest of the application source code
COPY . .

# Stage 2: Production - Creates a lean final image for deployment
FROM node:lts-alpine AS production

# Set the working directory
WORKDIR /app

# Set environment variable to indicate a production environment
ENV NODE_ENV=production

# Create a non-root user and switch to it for enhanced security.
# Running applications as non-root users is a security best practice.
# `addgroup -S appgroup` creates a system group.
# `adduser -S appuser -G appgroup` creates a system user `appuser` and adds it to `appgroup`.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copy only the necessary files from the builder stage:
# 1. node_modules (production dependencies)
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules

# 2. package.json and package-lock.json (needed for `npm start`)
COPY --from=builder --chown=appuser:appgroup /app/package*.json ./

# 3. Application source code (excluding node_modules which are already copied)
COPY --from=builder --chown=appuser:appgroup /app/. .

# Expose the port the application listens on.
# Node.js applications commonly listen on port 3000 by default.
# Ensure this matches the port your application is configured to use.
EXPOSE 3000

# Define the command to run the application.
# This executes the "start" script defined in your package.json,
# which is "node index.js" based on the provided data.
CMD ["npm", "start"]