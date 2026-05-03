# Use Node.js 20 base image
FROM node:20-slim AS builder

# Set working directory
WORKDIR /app

# Copy root package.json for monorepo context if needed
COPY package*.json ./

# --- Build Frontend ---
WORKDIR /app/client
COPY client/package*.json ./
RUN npm install
COPY client/ ./
# Build the client (Vite output goes to /app/client/dist)
RUN npm run build

# --- Build Backend ---
WORKDIR /app/server
COPY server/package*.json ./
RUN npm install --production
COPY server/ ./

# --- Final Image ---
FROM node:20-slim

WORKDIR /app

# Copy backend dependencies
COPY --from=builder /app/server/node_modules ./server/node_modules
# Copy backend source
COPY --from=builder /app/server ./server
# Copy frontend build
COPY --from=builder /app/client/dist ./client/dist

# Set environment variables
ENV NODE_ENV=production
ENV PORT=8080

# Cloud Run uses PORT 8080 by default
EXPOSE 8080

# Start the server
CMD ["node", "server/server.js"]
