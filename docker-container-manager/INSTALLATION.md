# Docker Container Manager - Installation & Testing Guide

This guide will help you install and test the Docker Container Manager VSCode extension.

## Prerequisites

Before installing the extension, ensure you have:

1. **Docker Desktop** (or Docker Engine) installed and running
2. **VSCode** version 1.80.0 or higher
3. **Node.js** version 16 or higher (for building from source)
4. **npm** package manager

## Installation Methods

### Method 1: Install from Source (Development)

1. **Clone the repository**:
   ```bash
   git clone https://github.com/markpatterson27/devcontainer-tests.git
   cd devcontainer-tests/docker-container-manager
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Compile the extension**:
   ```bash
   npm run compile
   ```

4. **Open in VSCode**:
   ```bash
   code .
   ```

5. **Launch the Extension Development Host**:
   - Press `F5` or go to Run > Start Debugging
   - A new VSCode window will open with the extension loaded
   - The extension icon will appear in the activity bar (left sidebar)

### Method 2: Install from VSIX Package

1. **Build the VSIX package**:
   ```bash
   cd docker-container-manager
   npm install
   npm run compile
   
   # Install vsce if you don't have it
   npm install -g @vscode/vsce
   
   # Package the extension
   vsce package
   ```

2. **Install in VSCode**:
   - Open VSCode
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Extensions: Install from VSIX..."
   - Select the `docker-container-manager-0.0.1.vsix` file
   - Reload VSCode when prompted

## Using the Extension

### First Time Setup

1. **Open the Docker Containers view**:
   - Click the container icon in the activity bar (left sidebar)
   - You'll see a tree view with four database containers

2. **Check Docker is running**:
   ```bash
   docker --version
   docker ps
   ```
   Make sure Docker daemon is running before proceeding.

3. **Pull your first image**:
   - In the tree view, find a container with "Image not pulled" status
   - Click the cloud download icon (⬇) next to it
   - Wait for the download to complete (this may take a few minutes)

4. **Start a container**:
   - Once the image is pulled, the status changes to "Stopped"
   - Click the play icon (▶) to start the container
   - The status will update to "Running on port X"

5. **Connect to the database**:
   Use these connection details in your application or database client:

   **SQL Server:**
   - Host: `localhost` or `127.0.0.1`
   - Port: `1433`
   - Username: `sa`
   - Password: `P@ssw0rd`

   **PostgreSQL:**
   - Host: `localhost` or `127.0.0.1`
   - Port: `5432`
   - Username: `postgres`
   - Password: `P@ssw0rd`
   - Database: `devcontainer_db`

   **MariaDB:**
   - Host: `localhost` or `127.0.0.1`
   - Port: `3306`
   - Username: `root`
   - Password: `P@ssw0rd`
   - Database: `devcontainer_db`

   **Redis:**
   - Host: `localhost` or `127.0.0.1`
   - Port: `6379`

### Testing the Extension

#### Test 1: Pull an Image
1. Click the cloud download icon next to "SQL Server"
2. Verify you see a progress notification
3. Wait for the "Successfully pulled SQL Server image" message
4. Verify the status changes to "Stopped"

#### Test 2: Start a Container
1. Click the play icon next to the stopped SQL Server container
2. Verify you see a progress notification
3. Wait for the "SQL Server started successfully on port 1433" message
4. Verify the status changes to "Running on port 1433"

#### Test 3: Verify Container is Running
```bash
docker ps
```
You should see the `mssql-devcontainer` container in the list.

#### Test 4: Stop a Container
1. Click the stop icon next to the running SQL Server container
2. Verify you see a progress notification
3. Wait for the "SQL Server stopped successfully" message
4. Verify the status changes to "Stopped"

#### Test 5: Refresh Status
1. Start a container using the extension
2. Manually stop it using Docker CLI: `docker stop mssql-devcontainer`
3. Click the refresh icon at the top of the tree view
4. Verify the status updates to "Stopped"

## Troubleshooting

### Extension Doesn't Appear
- Ensure you're using VSCode 1.80.0 or higher
- Try reloading VSCode: `Ctrl+Shift+P` → "Developer: Reload Window"
- Check the Output panel for errors: View → Output → "Log (Extension Host)"

### Cannot Pull Images
- Check your internet connection
- Verify Docker is running: `docker info`
- Check Docker Hub is accessible
- For corporate networks, ensure Docker registry access is not blocked

### Cannot Start Containers
- Ensure the image is pulled first
- Check if ports are already in use:
  ```bash
  # Windows
  netstat -ano | findstr :1433
  
  # Linux/Mac
  lsof -i :1433
  ```
- Check Docker logs: `docker logs mssql-devcontainer`

### Wrong Container Status
- Click the refresh icon
- Wait a few seconds after operations complete
- Check Docker directly: `docker ps -a`

### Permission Errors
- On Linux, ensure your user is in the docker group:
  ```bash
  sudo usermod -aG docker $USER
  # Log out and back in for changes to take effect
  ```

## Development Commands

```bash
# Install dependencies
npm install

# Compile TypeScript
npm run compile

# Watch mode (auto-compile on changes)
npm run watch

# Run linter
npm run lint

# Package extension
vsce package
```

## Uninstalling

### Development Installation
Simply close the Extension Development Host window.

### VSIX Installation
1. Open VSCode Extensions view (`Ctrl+Shift+X`)
2. Find "Docker Container Manager"
3. Click the gear icon → Uninstall
4. Reload VSCode

## Support

For issues, questions, or contributions:
- GitHub: https://github.com/markpatterson27/devcontainer-tests
- Report bugs in the Issues section

## Security Notes

⚠️ **This extension is for development use only**:
- Default passwords are used for convenience
- Do not expose containers to public networks
- Do not use in production environments
- Change passwords for any sensitive data

## What's Next?

After installing and testing the extension, you can:
1. Start all four database containers for your development needs
2. Test your application against different databases
3. Quickly switch between database systems
4. Stop containers when not needed to save resources

Enjoy using the Docker Container Manager! 🐳
