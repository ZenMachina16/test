# Stage 1: Builder
# Uses a lightweight Node.js Alpine image for efficient dependency installation.
FROM node:lts-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (if present) to leverage Docker layer caching.
# This ensures that 'npm ci' only runs if dependencies change, speeding up subsequent builds.
COPY package.json package-lock.json* ./

# Install production dependencies.
# 'npm ci' ensures reproducible builds by installing exact versions from package-lock.json.
# '--omit=dev' prevents development dependencies from being installed, resulting in a smaller final image.
# '--loglevel verbose' provides detailed output during installation, helpful for debugging.
RUN npm ci --omit=dev --loglevel verbose

# Copy the rest of the application source code into the working directory.
COPY . .

# Stage 2: Production
# Uses the same lightweight Node.js Alpine image for consistency and small footprint.
FROM node:lts-alpine AS production

# Set the working directory inside the container for the final application.
WORKDIR /app

# Set environment variables for production.
# NODE_ENV set to production for Node.js optimizations.
# PORT defines the port the application will listen on. Default to 3000, but can be overridden.
ENV NODE_ENV=production
ENV PORT=3000

# Copy only the necessary files from the builder stage to the production stage.
# This keeps the final image lean by excluding build tools and development files.
# Copy node_modules
COPY --from=builder /app/node_modules ./node_modules
# Copy application source code
COPY --from=builder /app ./

# Use a non-root user for enhanced security.
# The 'node' user is provided by the official Node.js Docker images.
USER node

# Expose the port on which the application will listen.
# This informs Docker that the container listens on the specified network port at runtime.
EXPOSE ${PORT}

# Healthcheck to verify the application is running and responsive.
# This assumes the application provides an HTTP endpoint on the exposed port (e.g., a simple root path).
# --interval: how often to run the check (30s)
# --timeout: how long the check can take before it's considered failed (10s)
# --start-period: grace period for the container to initialize (30s)
# --retries: how many consecutive failures before the container is considered unhealthy (3)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD curl -f http://localhost:${PORT} || exit 1

# Define the command to run the application.
# This uses the 'start' script defined in your package.json, which is "node index.js".
CMD ["npm", "start"]