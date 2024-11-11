#!/bin/bash
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

# Function to install cogs
install_cogs() {
    local cog=$1
    log "Installing cog: $cog"
    redbot instance --no-prompt --load-cogs $cog || {
        log "Warning: Failed to install cog $cog"
        return 1
    }
}

# Function to setup basic configuration
setup_basic_config() {
    log "Setting up basic configuration..."
    mkdir -p /app/data/config
    
    # Set default locale if not set
    if [ -z "$REDBOT_LOCALE" ]; then
        export REDBOT_LOCALE="en-US"
    fi
}

# Function to configure Lavalink
setup_lavalink() {
    log "Setting up Lavalink configuration..."
    local config_dir="/app/data/config/instance/Audio"
    mkdir -p "$config_dir"
    
    # If custom nodes are provided, use them
    if [ ! -z "$LAVALINK_NODES" ]; then
        echo "$LAVALINK_NODES" > "$config_dir/external_nodes.json"
    else
        # Create default node configuration
        cat > "$config_dir/external_nodes.json" <<EOF
[
    {
        "host": "${LAVALINK_HOST}",
        "port": ${LAVALINK_PORT},
        "password": "${LAVALINK_PASSWORD}",
        "ssl": ${LAVALINK_SSL:-false},
        "name": "primary"
    }
]
EOF
    fi
    
    # Create audio config file
    cat > "$config_dir/settings.json" <<EOF
{
    "use_external_lavalink": ${USE_LAVALINK:-false},
    "localtrack_folder": "/app/data/audio_cache",
    "max_queue_size": 1000,
    "auto_play": false,
    "disconnect": false,
    "daily_playlists": false,
    "global_db": true,
    "global_db_get_timeout": 5,
    "status": false,
    "server_local": false,
    "restrict": true,
    "jukebox": false,
    "jukebox_price": 0,
    "countrycode": "US",
    "prefer_lyrics": false,
    "empty_queue_timeout": 0,
    "volume": 100
}
EOF
}

# Initialize instance if it doesn't exist
if [ ! -d "/app/data/data/instance" ]; then
    log "Initializing new Red Discord bot instance..."
    redbot-setup --no-prompt --instance-name instance --data-path /app/data
    setup_basic_config
fi

# Install default cogs if specified
if [ ! -z "$DEFAULT_COGS" ]; then
    log "Installing default cogs..."
    IFS=',' read -ra DEFAULT_COG_LIST <<< "$DEFAULT_COGS"
    for cog in "${DEFAULT_COG_LIST[@]}"; do
        cog=$(echo $cog | xargs)
        install_cogs $cog
    done
fi

# Install additional cogs from environment variable
if [ ! -z "$REDBOT_COGS" ]; then
    log "Installing additional cogs..."
    IFS=',' read -ra COGS <<< "$REDBOT_COGS"
    for cog in "${COGS[@]}"; do
        cog=$(echo $cog | xargs)
        install_cogs $cog
    done
fi

# Setup audio if enabled
if [ "$ENABLE_AUDIO" = "true" ]; then
    log "Setting up audio features..."
    redbot instance --no-prompt --load-cogs audio
    
    # Configure Lavalink if enabled
    if [ "$USE_LAVALINK" = "true" ]; then
        if [ -z "$LAVALINK_HOST" ] || [ -z "$LAVALINK_PORT" ] || [ -z "$LAVALINK_PASSWORD" ]; then
            log "Error: Lavalink is enabled but required configuration is missing!"
            exit 1
        fi
        setup_lavalink
        log "Lavalink configuration completed"
    fi
fi

# Verify token exists
if [ -z "$DISCORD_TOKEN" ]; then
    log "Error: DISCORD_TOKEN is not set!"
    exit 1
fi

# Set default prefix if not provided
if [ -z "$BOT_PREFIX" ]; then
    export BOT_PREFIX="!"
    log "No prefix specified, using default: !"
fi

log "Starting Red Discord bot..."
exec redbot instance \
    --token "$DISCORD_TOKEN" \
    --prefix "$BOT_PREFIX" \
    --no-prompt
