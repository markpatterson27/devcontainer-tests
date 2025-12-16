# devcontainer Tests

Testing devcontainer configurations.

## Docker Container Manager Extension

This repository includes a VSCode extension for easily managing Docker containers for development databases. The extension provides a visual interface for pulling images and starting/stopping containers for SQL Server, PostgreSQL, MariaDB, and Redis.

**Key Features:**
- Visual container management in VSCode sidebar
- One-click pull, start, and stop operations
- Support for SQL Server, PostgreSQL, MariaDB, and Redis
- Real-time container status indicators

**Location:** [`docker-container-manager/`](docker-container-manager/)

For detailed installation and usage instructions, see the [extension README](docker-container-manager/EXTENSION_README.md).

## Cloud Development Environment

### Requirements

devcontainer/codespace configurations required for developing cloud dev applications.

- dotnet
- python
- ms sql
- sqlite
- docker in docker
- az cli

### Experiments with Base Images

- Universal
- Ubuntu
- Debian
- dotnet
- pre-build

