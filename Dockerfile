# Build Stage: Install dependencies and build application
FROM node:20-alpine AS builder
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy app source
COPY . .

# Production Stage: Lean, secure image
FROM node:20-alpine AS production
ENV NODE_ENV=production

# Create non-root user
RUN addgroup -S nodejs && adduser -S nodejs -G nodejs
WORKDIR /usr/src/app

# Copy dependencies and code from builder
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder --chown=nodejs:nodejs /usr/src/app .

USER nodejs

EXPOSE 8080
CMD [ "node", "index.js" ]
