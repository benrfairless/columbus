# Columbus Docker Setup

This guide explains how to run Columbus using Docker and Docker Compose.

## Prerequisites

- Docker Engine 20.10 or later
- Docker Compose 2.0 or later

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/elmasy-com/columbus.git
cd columbus
```

2. Start all services with Docker Compose:
```bash
docker-compose up -d
```

This will start:
- MongoDB database
- Columbus Server (API) on port 8080
- Columbus Scanner (Certificate Transparency log scanner)
- Columbus DNS server on port 1053

3. Access the web interface:
```bash
open http://localhost:8080
```

4. Test the API:
```bash
curl 'http://localhost:8080/api/lookup/github.com'
```

## Services

### Columbus Server
The main API server that provides the subdomain lookup service.
- **Port**: 8080
- **Config**: Uses `server/server.docker.conf`
- **Health**: Check `http://localhost:8080/`

### Columbus Scanner
Parses Certificate Transparency logs and inserts subdomains into the database.
- **Config**: Uses `scanner/scanner.docker.conf`
- **Note**: Requires a valid LogName to be set in the config

### Columbus DNS
A DNS server that collects queried domains.
- **Ports**: 1053 (UDP and TCP)
- **Config**: Uses `dns/dns.docker.conf`
- **Usage**: Set your DNS to `localhost:1053` to contribute

### MongoDB
The database backend for storing subdomains.
- **Port**: 27017
- **Data**: Persisted in Docker volume `columbus_mongodb_data`

## Configuration

### Environment Variables

You can customize MongoDB credentials by creating a `.env` file:

```bash
cp .env.example .env
```

Edit `.env`:
```
MONGO_ROOT_USERNAME=admin
MONGO_ROOT_PASSWORD=your_secure_password
```

Then restart the services:
```bash
docker-compose down -v
docker-compose up -d
```

### Custom Configuration

To use custom configuration files, you can mount them as volumes in `docker-compose.yml`:

```yaml
services:
  server:
    volumes:
      - ./my-custom-server.conf:/etc/columbus/server.conf:ro
```

## Management

### Start services
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f server
docker-compose logs -f scanner
docker-compose logs -f dns
```

### Restart a service
```bash
docker-compose restart server
```

### Rebuild after code changes
```bash
docker-compose up -d --build
```

### Remove all data (including database)
```bash
docker-compose down -v
```

## Building Individual Docker Images

If you prefer to build individual components:

### Server
```bash
docker build --target server -t columbus-server .
docker run -d -p 8080:8080 --name columbus-server columbus-server
```

### Scanner
```bash
docker build --target scanner -t columbus-scanner .
docker run -d --name columbus-scanner columbus-scanner
```

### DNS
```bash
docker build --target dns -t columbus-dns .
docker run -d -p 1053:1053/udp -p 1053:1053/tcp --name columbus-dns columbus-dns
```

## Troubleshooting

### Services won't start
Check logs for specific errors:
```bash
docker-compose logs
```

### MongoDB connection issues
Ensure MongoDB is healthy before other services start:
```bash
docker-compose ps
```

### Port conflicts
If ports 8080, 1053, or 27017 are already in use, modify them in `docker-compose.yml`:
```yaml
ports:
  - "8081:8080"  # Change host port to 8081
```

### Reset everything
```bash
docker-compose down -v
docker system prune -a
docker-compose up -d --build
```

## Production Deployment

For production use:

1. Use strong MongoDB credentials in `.env`
2. Consider using Docker secrets for sensitive data
3. Enable SSL/TLS for the server (configure in `server.docker.conf`)
4. Set up proper logging and monitoring
5. Use a reverse proxy (nginx, traefik) for the server
6. Consider resource limits in docker-compose.yml:

```yaml
services:
  server:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
```

## Development

For development with live reload, you can mount the source code:

```yaml
services:
  server:
    volumes:
      - .:/app
    command: sh -c "cd /app && go run ./server/."
```

## Support

For issues and questions:
- GitHub Issues: https://github.com/elmasy-com/columbus/issues
- Documentation: See README.md in the repository root
