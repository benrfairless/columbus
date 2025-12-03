# Columbus Docker Quick Reference

## Quick Start Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Restart a specific service
docker compose restart server
```

## Service URLs

- **Server (API)**: http://localhost:8080
- **MongoDB**: mongodb://localhost:27017
- **DNS Server**: localhost:1053 (UDP/TCP)

## Configuration

Default credentials are set in the Docker config files. To change MongoDB credentials:

1. Copy `.env.example` to `.env`
2. Update `MONGO_ROOT_USERNAME` and `MONGO_ROOT_PASSWORD`
3. Restart: `docker compose down -v && docker compose up -d`

## Useful Commands

```bash
# View all running containers
docker compose ps

# Check logs for a specific service
docker compose logs -f server
docker compose logs -f scanner
docker compose logs -f dns

# Execute command in running container
docker compose exec server /bin/sh

# Rebuild after code changes
docker compose up -d --build

# Clean up everything (including data!)
docker compose down -v
docker system prune -a

# Build only specific service
docker compose build server

# Scale a service (if stateless)
docker compose up -d --scale scanner=3
```

## Testing the Setup

```bash
# Test the API
curl http://localhost:8080/api/lookup/github.com

# Test DNS server (requires dig)
dig @localhost -p 1053 example.com

# Check MongoDB connection
docker compose exec mongodb mongosh -u admin -p changeme
```

## Troubleshooting

**Services won't start:**
```bash
docker compose logs
```

**Port already in use:**
Edit `docker-compose.yml` and change the host port:
```yaml
ports:
  - "8081:8080"  # Change 8080 to 8081
```

**MongoDB connection issues:**
Check if MongoDB is healthy:
```bash
docker compose ps
```

**Reset everything:**
```bash
docker compose down -v
docker system prune -a
docker compose up -d
```

## For More Information

See [DOCKER.md](DOCKER.md) for comprehensive documentation.
