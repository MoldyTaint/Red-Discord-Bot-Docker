FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    build-essential \
    libffi-dev \
    libnacl-dev \
    python3-dev \
    ffmpeg \
    opus-tools \
    libopus0 \
    libopus-dev \
    # Required for voice support
    libsodium-dev \
    # Required for some cogs
    wget \
    unzip \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -u 1000 redbot

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install -U pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Create necessary directories
RUN mkdir -p /app/data && \
    chown -R redbot:redbot /app

# Switch to non-root user
USER redbot

ENTRYPOINT ["/app/entrypoint.sh"]
