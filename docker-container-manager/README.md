# Docker Container Manager

A VSCode extension that makes it easy to pull, start and stop Docker containers for SQL Server, PostgreSQL, MariaDB and Redis.

## Features

- **Visual Container Management**: View the status of your database containers in a dedicated sidebar
- **One-Click Operations**: Pull images, start and stop containers with a single click
- **Supported Databases**:
  - SQL Server (2019)
  - PostgreSQL (latest)
  - MariaDB (latest)
  - Redis (latest)

## Usage

1. Open the Docker Containers view from the activity bar
2. You'll see all available database containers with their current status
3. For containers not yet pulled, click the cloud download icon to pull the image
4. Once pulled, click the play icon to start the container
5. Click the stop icon to stop a running container

## Container Details

### SQL Server
- **Port**: 1433
- **Password**: P@ssw0rd
- **Container Name**: mssql-devcontainer

### PostgreSQL
- **Port**: 5432
- **Password**: P@ssw0rd
- **Database**: devcontainer_db
- **Container Name**: postgres-devcontainer

### MariaDB
- **Port**: 3306
- **Root Password**: P@ssw0rd
- **Database**: devcontainer_db
- **Container Name**: mariadb-devcontainer

### Redis
- **Port**: 6379
- **Container Name**: redis-devcontainer

## Requirements

- Docker must be installed and running on your system
- Docker daemon must be accessible from the command line

## Security Considerations

**⚠️ Development Use Only**: This extension is designed for local development environments. The containers use default passwords (`P@ssw0rd`) for convenience during development. 

**Important Security Notes**:
- Do not use these containers in production environments
- Do not expose these containers to public networks
- The default passwords are intended for local development only
- For production use, always configure secure passwords and proper authentication

## Extension Settings

This extension does not add any VS Code settings.

## Known Issues

None at this time.

## Release Notes

### 0.0.1

Initial release of Docker Container Manager

- Support for SQL Server, PostgreSQL, MariaDB, and Redis
- Pull, start, and stop operations
- Visual status indicators
