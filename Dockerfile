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
    # Required for audio playback
    youtube-dl \
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

# Install Red-DiscordBot and common dependencies
RUN pip install -U pip setuptools wheel && \
    pip install Red-DiscordBot[voice] && \
    # Install common audio-related dependencies
    pip install youtube_dl && \
    pip install PyNaCl

# Pre-install common cogs dependencies
RUN pip install beautifulsoup4 tabulate matplotlib pillow

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Create necessary directories
RUN mkdir -p /app/data && \
    chown -R redbot:redbot /app

# Switch to non-root user
USER redbot

ENTRYPOINT ["/app/entrypoint.sh"]
