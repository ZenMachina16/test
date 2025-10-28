# Stage 1: Builder - Installs dependencies and prepares the application
FROM node:20-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (if present) first.
# This allows Docker to cache the dependency installation step.
# Future builds are faster if only application code changes.
COPY package.json ./

# Install application dependencies.
# 'npm ci' is preferred for production builds as it ensures a clean and consistent
# installation based on package-lock.json, avoiding potential discrepancies.
# '--omit=dev' ensures that only production dependencies are installed,
# keeping the final image smaller and more secure.
RUN npm ci --omit=dev

# Copy the rest of the application source code to the builder stage.
# It's recommended to use a .dockerignore file to exclude unnecessary files
# like .git, node_modules (from host), and local development artifacts.
COPY . .

# If your application has a build step (e.g., for React, Angular, Vue, or TypeScript),
# it would typically be executed here. For a simple Node.js app running 'index.js',
# this step might not be necessary.
# Example: RUN npm run build

# Stage 2: Production - Creates a lean final image for deployment
FROM node:20-alpine AS production

# Set the working directory inside the container
WORKDIR /app

# Copy only the necessary files from the builder stage to the production stage.
# This keeps the production image minimal and secure, excluding build tools
# and development dependencies.
# Copy node_modules separately to ensure it's in the correct place.
COPY --from=builder /app/node_modules ./node_modules
# Copy the rest of the application files.
COPY --from=builder /app ./

# Expose the port your application listens on.
# For Node.js applications, common ports are 3000 or 8080.
# It's good practice to configure your application to use an environment variable (e.g., process.env.PORT)
# for the port, allowing dynamic configuration.
EXPOSE 3000

# Run the application as a non-root user for enhanced security.
# The 'node:alpine' image typically includes a 'node' user with appropriate permissions.
USER node

# Define the command to run the application.
# The "start" script is defined in package.json: "start": "node index.js".
# Using "npm start" is idiomatic and leverages the script defined in package.json.
CMD ["npm", "start"]