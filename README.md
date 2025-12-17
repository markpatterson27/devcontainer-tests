# devcontainer Tests

Testing devcontainer configurations.

## Services Manager Extension

This repository includes a VSCode extension for easily managing development services including databases and caches. The extension provides a visual interface organized by service type, with expandable service details showing connection information.

**Key Features:**
- Services grouped by type (Databases, Caches)
- Expandable service details (port, username, password, database)
- One-click pull, start, and stop operations
- Support for SQL Server, PostgreSQL, MariaDB, and Redis
- Easy to extend with new services

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

