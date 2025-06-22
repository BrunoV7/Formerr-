# Multi-stage build para otimizar o tamanho da imagem e cache
FROM python:3.11-slim as base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# ============================================================================
# Dependencies stage - for better layer caching
# ============================================================================
FROM base as dependencies

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ============================================================================
# Production stage
# ============================================================================
FROM base as production

# Copy installed packages from dependencies stage
COPY --from=dependencies /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=dependencies /usr/local/bin /usr/local/bin

# Copy application code
COPY . .

# Build arguments for environment variables (can be overridden at build time)
ARG ENVIRONMENT=production
ARG DATABASE_URL=postgresql://user:pass@localhost/formerr
ARG GITHUB_CLIENT_ID=""
ARG GITHUB_CLIENT_SECRET=""
ARG JWT_SECRET=""
ARG SESSION_SECRET=""
ARG FRONTEND_SUCCESS_URL=http://localhost:3000/auth/success
ARG FRONTEND_ERROR_URL=http://localhost:3000/auth/error
ARG OAUTH_CALLBACK_URL=http://localhost:8000/auth/github/callback
ARG ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173

# Set environment variables (will use ARG values as defaults)
ENV ENVIRONMENT=${ENVIRONMENT}
ENV DATABASE_URL=${DATABASE_URL}
ENV GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}
ENV GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}
ENV JWT_SECRET=${JWT_SECRET}
ENV SESSION_SECRET=${SESSION_SECRET}
ENV FRONTEND_SUCCESS_URL=${FRONTEND_SUCCESS_URL}
ENV FRONTEND_ERROR_URL=${FRONTEND_ERROR_URL}
ENV OAUTH_CALLBACK_URL=${OAUTH_CALLBACK_URL}
ENV ALLOWED_ORIGINS=${ALLOWED_ORIGINS}

# Create necessary directories and change ownership
RUN mkdir -p /app/logs && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
