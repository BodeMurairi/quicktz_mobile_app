# ── Stage 1: dependencies ─────────────────────────────────────────────────────
FROM python:3.11-slim AS deps

WORKDIR /app

# Install system deps needed by asyncpg / Pillow
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Stage 2: runtime ──────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copy installed packages from deps stage
COPY --from=deps /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=deps /usr/local/bin /usr/local/bin

# Runtime libpq (needed by asyncpg)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
  && rm -rf /var/lib/apt/lists/*

COPY . .

EXPOSE 8000

# Use 4 workers in production; override via WORKERS env var
CMD uvicorn main:app \
      --host 0.0.0.0 \
      --port 8000 \
      --workers ${WORKERS:-4} \
      --log-level ${LOG_LEVEL:-info}
