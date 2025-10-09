# Stage 1: Builder - Install dependencies and prepare application files
# This stage uses a full Node.js environment to install all dependencies,
# including development dependencies if they are required for a build step.
# It then prunes development dependencies to keep the final image lean.
FROM node:lts-alpine as builder

# Set the working directory inside the container for all subsequent commands
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock) first.
# This allows Docker to cache the dependency installation step.
# If these files haven't changed, Docker will reuse the cached layer, speeding up builds.
COPY package.json package-lock.json ./

# Install project dependencies.
# 'npm ci' is used for reproducible builds, ensuring the exact versions
# specified in package-lock.json are installed.
# By default, 'npm ci' installs all dependencies (production and development).
RUN npm ci

# Copy the rest of the application source code into the working directory.
COPY . .

# Prune development dependencies from node_modules.
# This step significantly reduces the size of the node_modules directory,
# as development-only packages are not needed at runtime in production.
RUN npm prune --production

# Stage 2: Production - Create the final, optimized, and minimal image
# This stage uses a lightweight Node.js base image suitable for production.
FROM node:lts-alpine

# Set the working directory for the application in the production image
WORKDIR /app

# Set environment variables for the production environment.
# NODE_ENV=production optimizes Node.js runtime performance and behavior.
# PORT defines the network port the application is expected to listen on.
ENV NODE_ENV=production
ENV PORT=3000

# Copy only the necessary files from the builder stage into the final image.
# This includes the pruned node_modules and the application source code.
# This multi-stage approach ensures that build tools and unnecessary files
# from the builder stage are not included in the final production image,
# leading to a smaller, more secure, and faster-to-deploy image.
COPY --from=builder /app .

# Create a non-root user and set appropriate ownership and permissions.
# Running the application as a non-root user significantly enhances security
# by limiting potential damage in case of a security vulnerability.
# 'nodejs' user and group are created with specific UIDs/GIDs for consistency.
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs && \
    chown -R nodejs:nodejs /app

# Switch to the non-root user for running the application.
USER nodejs

# Expose the port on which the application listens.
# This informs Docker that the container will listen on this port at runtime.
# It's a declaration and doesn't publish the port; 'docker run -p' is needed for that.
EXPOSE ${PORT}

# Define the command to run the application when the container starts.
# This executes the "start" script defined in the package.json file.
CMD ["npm", "start"]

# --- Best Practices / Considerations ---
# 1. .dockerignore: Ensure you have a .dockerignore file in your project root.
#    It should exclude unnecessary files and directories from being copied into the image,
#    such as 'node_modules' (as it's installed inside), '.git', '.vscode', build artifacts, etc.
#    Example .dockerignore content:
#    node_modules
#    .git
#    .vscode
#    npm-debug.log*
#    Dockerfile*
#    .dockerignore
#    README.md
#    .env
#
# 2. Health Checks (Optional but Recommended for Production):
#    For robust deployments, consider adding a HEALTHCHECK instruction.
#    This allows Docker and orchestrators (like Kubernetes) to determine
#    if your container is still alive and serving requests.
#    Example (requires your app to expose a /health endpoint):
#    HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#      CMD node -e "require('http').get('http://localhost:${PORT}/health', (res) => { \
#        if (res.statusCode !== 200) throw new Error('Healthcheck failed'); \
#      }).on('error', () => { throw new Error('Healthcheck failed'); });" || exit 1