# Red-DiscordBot Docker

This repository contains a fully-featured Dockerized version of the [Red-DiscordBot](https://github.com/Cog-Creators/Red-DiscordBot), making it easy to deploy and manage your Discord bot in a containerized environment.

## Features

- Easy configuration through environment variables
- Persistent data storage with separate volumes for different types of data
- Automatic cog installation and management
- Full audio support with both local and Lavalink options
- Resource management and monitoring
- Secure non-root execution
- Automated builds via GitHub Actions
- Pre-built images available via GitHub Container Registry
- Comprehensive logging and error handling
- Health monitoring
- IPv6 support

## Quick Start

### Using Pre-built Image (Recommended)

1. Clone this repository:
```bash
git clone https://github.com/MoldyTaint/Red-Discord-Bot-Docker-
cd Red-Discord-Bot-Docker-
```

2. Create your environment file:
```bash
cp .env.example .env
```

3. Edit the `.env` file with your configuration:
- Add your Discord bot token
- Set your preferred command prefix
- Configure desired cogs and features
- Set up audio/Lavalink configuration if needed

4. Start the bot:
```bash
docker-compose up -d
```

### Building Locally (Alternative)

If you want to build the image locally instead of using the pre-built one:

1. Comment out the `image:` line in docker-compose.yml
2. Run:
```bash
docker-compose up -d --build
```

## Configuration

### Essential Environment Variables

- `DISCORD_TOKEN` (Required): Your Discord bot token
- `BOT_PREFIX` (Required): Command prefix for the bot (e.g., !)
- `DEFAULT_COGS`: Comma-separated list of cogs to install on first run
- `REDBOT_COGS`: Additional cogs to install
- `ENABLE_AUDIO`: Set to "true" to enable audio features
- `REDBOT_LOCALE`: Bot language (default: en-US)

### Audio Configuration

#### Local Audio (Default)
The bot comes with built-in audio support using YouTube-DL and FFmpeg. To use this:
1. Set `ENABLE_AUDIO=true` in your .env file
2. No additional configuration needed

#### Lavalink Support
For better audio performance, you can use an external Lavalink server:

1. Enable Lavalink in .env:
```env
USE_LAVALINK=true
LAVALINK_HOST=your_lavalink_host
LAVALINK_PORT=2333
LAVALINK_PASSWORD=your_password
LAVALINK_SSL=false  # Set to true if using SSL
```

2. For multiple Lavalink nodes, use LAVALINK_NODES:
```env
LAVALINK_NODES=[
  {
    "host": "primary.lavalink.com",
    "port": 2333,
    "password": "password1",
    "ssl": false
  },
  {
    "host": "backup.lavalink.com",
    "port": 2333,
    "password": "password2",
    "ssl": true
  }
]
```

#### Running Your Own Lavalink Server

This repository includes a pre-configured Lavalink setup:

1. Copy the Lavalink configuration:
```bash
cp lavalink-application.yml.example lavalink-application.yml
```

2. Edit lavalink-application.yml with your desired settings

3. Uncomment the Lavalink service in docker-compose.yml

4. Update your .env file to use the local Lavalink service:
```env
USE_LAVALINK=true
LAVALINK_HOST=lavalink
LAVALINK_PORT=2333
LAVALINK_PASSWORD=youshallnotpass
```

5. Start both services:
```bash
docker-compose up -d
```

### Advanced Audio Settings

- `AUDIO_CACHE_SIZE`: Maximum memory usage for audio caching (in MB)
- `AUDIO_MAX_DOWNLOADS`: Number of concurrent audio downloads
- `LAVALINK_SSL`: Enable SSL/TLS for Lavalink connection
- Custom node configuration via `LAVALINK_NODES`

## Data Persistence

The setup uses three separate Docker volumes for better organization and performance:
- `redbot_data`: Core bot data
- `redbot_config`: Configuration files
- `redbot_audio`: Audio cache files

## Pre-installed Features

### Default Cogs
The following cogs are included by default:
- general: Basic bot commands
- admin: Administrative commands
- mod: Moderation tools
- alias: Command aliases
- customcom: Custom commands
- downloader: Cog installation
- permissions: Permission management
- streams: Stream notifications
- cleanup: Message cleanup

### Audio Support
Full audio support is pre-configured with:
- FFmpeg for audio processing
- youtube-dl for media downloads
- Opus/Sodium libraries for voice
- Lavalink support
- Optimized cache management

## Resource Management

The container is configured with:
- Memory limits (2GB max, 512MB reserved)
- Automatic restart on failure
- Health monitoring
- Log rotation
- Security hardening

## Maintenance

### Viewing Logs
```bash
docker-compose logs -f
```

### Stopping the Bot
```bash
docker-compose down
```

### Updating the Bot

To update to the latest version:
```bash
docker-compose pull
docker-compose up -d
```

To update to a specific version:
1. Edit the image tag in docker-compose.yml
2. Run:
```bash
docker-compose up -d
```

### Backup

To backup your bot data:
```bash
docker run --rm -v redbot_data:/data -v $(pwd):/backup alpine tar czf /backup/redbot-backup.tar.gz /data
```

To restore from backup:
```bash
docker run --rm -v redbot_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/redbot-backup.tar.gz --strip 1"
```

## Troubleshooting

### Common Issues

1. Bot not starting:
   - Check if DISCORD_TOKEN is set correctly
   - Verify permissions in Discord developer portal

2. Audio not working:
   - Ensure ENABLE_AUDIO=true in .env
   - Check if the bot has proper voice permissions in Discord
   - Verify Lavalink configuration if using external server
   - Check Lavalink server logs if running locally

3. Memory issues:
   - Adjust memory limits in docker-compose.yml
   - Monitor logs for memory-related errors

4. Lavalink connection issues:
   - Verify Lavalink host and port are accessible
   - Check if password matches in both bot and Lavalink configs
   - Ensure SSL settings match between bot and server

### Debug Mode

To enable debug mode:
1. Set DEBUG=true in .env
2. Restart the container
3. Check logs for detailed information

## Security

- Runs as non-root user
- No new privileges allowed
- Resource limits enforced
- Separate volumes for different data types
- Regular security updates via automated builds

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Red-DiscordBot](https://github.com/Cog-Creators/Red-DiscordBot) team
- [Lavalink](https://github.com/freyacodes/Lavalink) team
- Discord.py developers
- Docker community

## Support

For issues and feature requests, please use the GitHub issues tracker.
