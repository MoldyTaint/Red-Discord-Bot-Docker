#!/usr/bin/env bash
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

# Verify required environment variables
if [ -z "$DISCORD_TOKEN" ]; then
    log "Error: DISCORD_TOKEN is not set!"
    exit 1
fi

if [ -z "$BOT_PREFIX" ]; then
    export BOT_PREFIX="!"
    log "No prefix specified, using default: !"
fi

# Clean up existing instance if it exists, but preserve volume mounts
log "Cleaning up existing data..."
if [ -d "/app/data" ]; then
    find /app/data -mindepth 1 -maxdepth 1 ! -name 'audio_cache' -exec rm -rf {} +
fi

# Create necessary directories
log "Creating directory structure..."
mkdir -p /app/data/config/instance
mkdir -p /app/data/audio_cache

# Create core configuration
log "Creating core configuration..."
cat > "/app/data/config/instance/core.json" <<EOF
{
    "token": "${DISCORD_TOKEN}",
    "prefix": ["${BOT_PREFIX}"],
    "locale": "${REDBOT_LOCALE:-en-US}",
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
    "extra_owner_dest_ids": [],
    "use_buttons": true,
    "use_slash_commands": true,
    "slash_commands": true,
    "force_slash_commands": true,
    "use_app_commands": true,
    "prefer_guild_commands": true,
    "sync_commands": true,
    "sync_commands_on_start": true,
    "sync_commands_globally": false,
    "sync_permissions": true
}
EOF

# Initialize instance
log "Initializing Red Discord bot instance..."
redbot-setup --no-prompt --instance-name instance --data-path /app/data

# Function to install cogs
install_cogs() {
    local cog=$1
    log "Installing cog: $cog"
    redbot instance --no-prompt --load-cogs $cog --token "${DISCORD_TOKEN}" --prefix "${BOT_PREFIX}" || {
        log "Warning: Failed to install cog $cog"
        return 1
    }
}

# Setup Streams configuration if Twitch credentials are provided
if [ ! -z "$TWITCH_CLIENT_ID" ] && [ ! -z "$TWITCH_CLIENT_SECRET" ]; then
    log "Setting up Twitch configuration..."
    mkdir -p "/app/data/config/instance/Streams"
    cat > "/app/data/config/instance/Streams/settings.json" <<EOF
{
    "twitch_client_id": "${TWITCH_CLIENT_ID}",
    "twitch_client_secret": "${TWITCH_CLIENT_SECRET}",
    "enable_twitch": true
}
EOF
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

# Install additional cogs
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
    mkdir -p "/app/data/config/instance/Audio"
    
    # Configure audio settings
    cat > "/app/data/config/instance/Audio/settings.json" <<EOF
{
    "use_external_lavalink": true,
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
    "volume": 100,
    "managed_node_controller": false
}
EOF
    
    # Configure Lavalink nodes
    if [ ! -z "$LAVALINK_NODES" ]; then
        echo "$LAVALINK_NODES" > "/app/data/config/instance/Audio/external_nodes.json"
    else
        cat > "/app/data/config/instance/Audio/external_nodes.json" <<EOF
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
    
    log "Audio configuration completed"
    redbot instance --no-prompt --load-cogs audio --token "${DISCORD_TOKEN}" --prefix "${BOT_PREFIX}"
fi

log "Starting Red Discord bot..."
exec redbot instance --token "${DISCORD_TOKEN}" --prefix "${BOT_PREFIX}" --no-prompt
