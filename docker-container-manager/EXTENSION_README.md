# Docker Container Manager Extension

This repository contains a VSCode extension for easily managing Docker containers for development databases.

## Extension Overview

The Docker Container Manager extension provides a visual interface in VSCode for managing Docker containers for SQL Server, PostgreSQL, MariaDB, and Redis. It simplifies the process of pulling images, starting, and stopping containers directly from the VSCode interface.

## Features

- **Visual Container Management**: View the status of your database containers in a dedicated sidebar
- **One-Click Operations**: Pull images, start and stop containers with a single click
- **Supported Databases**:
  - SQL Server (2019)
  - PostgreSQL (latest)
  - MariaDB (latest)
  - Redis (latest)

## Installation

### From Source

1. Clone this repository
2. Navigate to the `docker-container-manager` directory
3. Install dependencies:
   ```bash
   npm install
   ```
4. Compile the extension:
   ```bash
   npm run compile
   ```
5. Open the folder in VSCode and press F5 to launch the extension in a new Extension Development Host window

### From VSIX Package

1. Build the VSIX package:
   ```bash
   cd docker-container-manager
   npm install -g @vscode/vsce
   vsce package
   ```
2. Install the generated `.vsix` file in VSCode:
   - Open VSCode
   - Go to Extensions (Ctrl+Shift+X)
   - Click the "..." menu at the top
   - Select "Install from VSIX..."
   - Choose the generated `docker-container-manager-0.0.1.vsix` file

## Usage

1. **Open the Docker Containers view**: Click on the Docker Containers icon in the activity bar (left sidebar)
2. **View container status**: You'll see all available database containers with their current status:
   - "Image not pulled" - The Docker image hasn't been downloaded yet
   - "Stopped" - Container exists but is not running
   - "Running on port X" - Container is currently running
3. **Pull an image**: Click the cloud download icon (⬇) next to a container that hasn't been pulled
4. **Start a container**: Click the play icon (▶) next to a stopped container
5. **Stop a container**: Click the stop icon (⏹) next to a running container
6. **Refresh status**: Click the refresh icon at the top of the view to update container statuses

## Container Details

### SQL Server
- **Image**: mcr.microsoft.com/mssql/server:2019-latest
- **Port**: 1433
- **Username**: sa
- **Password**: P@ssw0rd
- **Container Name**: mssql-devcontainer

### PostgreSQL
- **Image**: postgres:latest
- **Port**: 5432
- **Username**: postgres
- **Password**: P@ssw0rd
- **Database**: devcontainer_db
- **Container Name**: postgres-devcontainer

### MariaDB
- **Image**: mariadb:latest
- **Port**: 3306
- **Username**: root
- **Root Password**: P@ssw0rd
- **Database**: devcontainer_db
- **Container Name**: mariadb-devcontainer

### Redis
- **Image**: redis:latest
- **Port**: 6379
- **Container Name**: redis-devcontainer

## Requirements

- Docker must be installed and running on your system
- Docker daemon must be accessible from the command line
- VSCode version 1.80.0 or higher

## Development

### Building the Extension

```bash
cd docker-container-manager
npm install
npm run compile
```

### Running Tests

Currently, no automated tests are included. Manual testing is recommended.

### Debugging

1. Open the `docker-container-manager` folder in VSCode
2. Press F5 to launch the extension in debug mode
3. A new VSCode window will open with the extension loaded

## Architecture

The extension consists of:

- **TreeDataProvider**: Manages the container list in the sidebar
- **Container Status Detection**: Uses Docker CLI to check image and container status
- **Command Handlers**: Execute Docker commands for pull, start, and stop operations
- **Progress Notifications**: Provides feedback during long-running operations

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is open source and available under the MIT License.

## Release Notes

### 0.0.1 (Initial Release)

- Support for SQL Server, PostgreSQL, MariaDB, and Redis containers
- Pull, start, and stop operations
- Visual status indicators
- Tree view in the activity bar
