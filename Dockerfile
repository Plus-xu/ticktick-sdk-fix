# ---- Build stage ----
FROM python:3.11-slim AS builder

WORKDIR /app

COPY pyproject.toml README.md LICENSE.md ./
COPY src/ src/

RUN pip install --no-cache-dir .

# ---- Runtime stage ----
FROM python:3.11-slim

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin/ticktick-sdk /usr/local/bin/ticktick-sdk
COPY --from=builder /app /app

# Install curl for health check
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

# Default environment for Docker (HTTP mode)
ENV TICKTICK_TRANSPORT=http
ENV PORT=8000

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["python", "-m", "ticktick_sdk"]
