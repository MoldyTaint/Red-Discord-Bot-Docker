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

    # Create basic config file
    local config_dir="/app/data/config/instance"
    mkdir -p "$config_dir"
    cat > "$config_dir/core.json" <<EOF
{
    "token": "${DISCORD_TOKEN}",
    "prefix": ["${BOT_PREFIX}"],
    "locale": "${REDBOT_LOCALE}",
    "no_cog_init": false,
    "owner": null,
    "owner_id": null,
    "embeds": true,
    "color": 15158332,
    "help__page_char_limit": 1000,
    "help__max_pages_in_guild": 2,
    "help__tagline": "Red V3",
    "help__use_menus": true,
    "help__show_hidden": false,
    "help__verify_checks": true,
    "help__verify_exists": true,
    "help__sort_commands": true,
    "help__commands_heading": "Commands:",
    "help__subcommands_heading": "Subcommands:",
    "help__aliases_heading": "Aliases:",
    "description": null,
    "invite_public": true,
    "invite_perm": 8,
    "invite_commands_scope": true,
    "disabled_commands": [],
    "disabled_command_msg": "That command is disabled.",
    "extra_owner_destinations": [],
    "extra_owner_dest_ids": []
}
EOF
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

# Clean up existing instance if it exists
if [ -d "/app/data/data/instance" ]; then
    log "Removing existing instance..."
    rm -rf /app/data/data/instance
fi

# Initialize instance
log "Initializing new Red Discord bot instance..."
redbot-setup --no-prompt --instance-name instance --data-path /app/data --overwrite-existing-instance
setup_basic_config

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

log "Starting Red Discord bot..."
exec redbot instance \
    --no-prompt
