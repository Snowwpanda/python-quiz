# Multi-stage build: Frontend + Backend in one deployment
FROM node:20-slim AS frontend-builder

WORKDIR /frontend

# Copy frontend files and install dependencies
COPY frontend/package*.json ./
RUN npm install

# Copy rest of frontend files
COPY frontend/ ./

# Build the frontend
RUN npm run build

# Final stage: Python backend with built frontend
FROM python:3.12-slim

# Install Node.js (needed to run the Astro SSR server)
RUN apt-get update && apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Set working directory
WORKDIR /app

# Copy backend files
COPY backend/pyproject.toml ./backend/
COPY backend/*.py ./backend/

# Install backend dependencies
WORKDIR /app/backend
RUN uv sync

# Copy built frontend from builder stage
WORKDIR /app
COPY --from=frontend-builder /frontend/dist ./frontend/dist
COPY --from=frontend-builder /frontend/node_modules ./frontend/node_modules
COPY --from=frontend-builder /frontend/package.json ./frontend/package.json

# Create startup script
RUN echo '#!/bin/bash\n\
cd /app/backend && uv run uvicorn main:app --host 0.0.0.0 --port 8080 &\n\
cd /app/frontend && node ./dist/server/entry.mjs &\n\
wait -n\n\
exit $?' > /app/start.sh && chmod +x /app/start.sh

# Expose ports (8080 for backend, 4321 for frontend)
EXPOSE 8080 4321

# Run both servers
CMD ["/app/start.sh"]
