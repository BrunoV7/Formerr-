# =============================================================================
# Simplified Dockerfile for Next.js Frontend
# Using Ubuntu base to avoid Alpine compatibility issues
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Dependencies installation
# -----------------------------------------------------------------------------
FROM node:20-slim AS deps

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies
RUN npm ci && npm cache clean --force

# -----------------------------------------------------------------------------
# Stage 2: Build application
# -----------------------------------------------------------------------------
FROM node:20-slim AS builder

WORKDIR /app

# Install system dependencies for build
RUN apt-get update && apt-get install -y \
    python3 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source code
COPY . .

# Build arguments for environment-specific builds
ARG NEXT_PUBLIC_API_URL=http://localhost:8000
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
ENV NODE_ENV=production

# Disable TypeScript and ESLint checks during build
ENV SKIP_TYPE_CHECK=true
ENV DISABLE_ESLINT=true
ENV CI=false

# Build the application
RUN npm run build:docker

# -----------------------------------------------------------------------------
# Stage 3: Production runtime
# -----------------------------------------------------------------------------
FROM node:20-slim AS production

# Create non-root user
RUN groupadd -r nodejs && useradd -r -g nodejs nextjs

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy built application (standalone mode)
COPY --from=builder /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Switch to non-root user
USER nextjs

# Environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000 || exit 1

# Start the application
CMD ["node", "server.js"]
