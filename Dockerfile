# Stage 1: Builder
# Use a lightweight Node.js base image suitable for building.
# Node.js 20 is a current LTS (Long Term Support) version.
# Alpine variant is chosen for its extremely small size, contributing to smaller final images.
FROM node:20-alpine AS builder

# Set the working directory inside the container. All subsequent commands will run from here.
WORKDIR /app

# Copy package.json and package-lock.json first.
# This step is critical for Docker's layer caching. If only your application code
# changes, but dependencies (package.json/package-lock.json) do not,
# Docker will reuse the cached 'npm install' layer, significantly speeding up subsequent builds.
# The '*' handles cases where package-lock.json might not be committed yet, though for production, it should be.
COPY package.json package-lock.json* ./

# Install production dependencies.
# 'npm ci' is preferred over 'npm install' in CI/CD and production environments
# because it ensures that you get the exact versions of dependencies specified
# in 'package-lock.json', leading to reproducible builds.
# '--only=production' ensures that only production dependencies are installed,
# further reducing the image size and potential attack surface.
RUN npm ci --only=production

# Copy the rest of the application's source code into the working directory.
COPY . .

# Stage 2: Production Environment
# Use a minimal Node.js runtime image for the final production container.
# This image contains only what's necessary to run the application,
# drastically reducing the final image size and attack surface.
FROM node:20-alpine

# Set the working directory for the production stage.
WORKDIR /app

# Copy only the necessary files from the builder stage to the final image.
# This includes 'node_modules' (production dependencies) and the application's source code.
# This prevents copying unnecessary build tools, development dependencies, or temporary files
# into the final production image.
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app ./

# Set environment variables for production.
# This informs Node.js and many libraries to optimize for performance and security.
ENV NODE_ENV=production

# Expose the port your application listens on.
# This is a declaration that the container listens on the specified network ports
# at runtime. It doesn't actually publish the port but serves as documentation
# and can be used by container orchestration tools (e.g., Kubernetes, Docker Compose).
# Based on common Node.js practices, we assume the application listens on port 3000.
# If your application listens on a different port, update this value accordingly.
EXPOSE 3000

# Security Best Practice: Run the application as a non-root user.
# Creating a dedicated non-root user and group for the application reduces the impact
# of a potential container breakout, as Node.js applications generally don't require root privileges.
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser

# Define the command to run your application when the container starts.
# This uses the "start" script defined in your package.json, which is
# "node index.js" according to your provided data.
CMD ["npm", "start"]