# Stage 1: Builder - Install dependencies and prepare application files
# Using a specific LTS version of Node.js for stability in production.
# The 'alpine' variant is chosen for a smaller image size.
FROM node:20-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (if present) first.
# This allows Docker to cache the dependency installation step,
# speeding up subsequent builds if these files haven't changed.
COPY package*.json ./

# Install application dependencies.
# 'npm ci' is preferred for production builds as it ensures reproducible installs
# by strictly adhering to package-lock.json.
# '--omit=dev' prevents installation of development dependencies, further reducing image size.
RUN npm ci --omit=dev

# Copy the rest of the application source code
COPY . .

# Stage 2: Production - Create the final, lean production image
# Re-using the same base image as the builder stage for consistency,
# but a smaller runtime-only image (e.g., node:20-slim, or gcr.io/distroless/nodejs)
# could be considered for even smaller footprints if specific shell utilities are not needed.
FROM node:20-alpine AS production

# Set the working directory inside the container
WORKDIR /app

# Set production environment variable
ENV NODE_ENV=production

# Copy only necessary files from the builder stage to the production image.
# This significantly reduces the final image size by not including build tools or dev dependencies.
COPY --from=builder /app/node_modules ./node_modules
# Copy package.json to the production image as it's needed by `npm start`
COPY --from=builder /app/package.json ./package.json
# Copy the application source code
COPY . .

# Expose the port on which the application will listen.
# Node.js applications commonly listen on port 3000, but adjust if your app uses a different one.
EXPOSE 3000

# Healthcheck to verify the application is running and responsive.
# This assumes your application exposes an HTTP endpoint on port 3000 (e.g., the root path '/').
# Adjust the URL or command if your application's health check differs.
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/ || exit 1

# Security Best Practice: Run the application as a non-root user.
# Create a dedicated system group and user, then change ownership of the /app directory.
# This mitigates potential security vulnerabilities.
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
RUN chown -R appuser:appgroup /app
USER appuser

# Define the command to run the application.
# This executes the "start" script defined in your package.json.
CMD ["npm", "start"]

# Important Note:
# For production readiness, create a `.dockerignore` file in the root of your project.
# This file tells Docker which files and directories to exclude when building the image,
# preventing unnecessary files (like .git, local node_modules, .env files, etc.)
# from being copied into the image, which can bloat its size and introduce security risks.
# A typical .dockerignore for a Node.js app might include:
# node_modules
# .git
# .env
# npm-debug.log*
# yarn-debug.log*
# yarn-error.log*
# .vscode
# Dockerfile
# README.md
# .dockerignore