# Visual Guide

## Extension Layout

The Docker Container Manager extension adds a new icon to the VSCode activity bar (the vertical bar on the left side of VSCode). When you click on it, you'll see a tree view panel displaying all managed database containers.

## Container Status Icons

The extension uses different icons to indicate container status:

- **Cloud Download Icon (⬇)**: Appears when the Docker image is not yet pulled. Click to download the image.
- **Circle Outline (○)**: Indicates the container is stopped. 
- **Play Icon (▶)**: Appears next to stopped containers. Click to start the container.
- **Filled Circle (●)**: Indicates the container is currently running.
- **Stop Icon (⏹)**: Appears next to running containers. Click to stop the container.

## Tree View Structure

```
Docker Containers
├─ 🗄️ SQL Server
│  └─ Status: Running on port 1433
├─ 🗄️ PostgreSQL
│  └─ Status: Stopped
├─ 🗄️ MariaDB
│  └─ Status: Image not pulled
└─ 🗄️ Redis
   └─ Status: Running on port 6379
```

## Actions

### Pull Image
1. Locate a container with "Image not pulled" status
2. Click the cloud download icon next to it
3. Wait for the pull operation to complete (progress shown in notification)
4. The status will update to "Stopped" once pulled

### Start Container
1. Locate a stopped container
2. Click the play icon next to it
3. Wait for the container to start (progress shown in notification)
4. The status will update to "Running on port X"

### Stop Container
1. Locate a running container
2. Click the stop icon next to it
3. Wait for the container to stop (progress shown in notification)
4. The status will update to "Stopped"

### Refresh View
- Click the refresh icon at the top of the tree view to update all container statuses

## Connection Information

After starting a container, use these connection details in your application:

### SQL Server
- **Host**: localhost or 127.0.0.1
- **Port**: 1433
- **Username**: sa
- **Password**: P@ssw0rd

### PostgreSQL
- **Host**: localhost or 127.0.0.1
- **Port**: 5432
- **Username**: postgres
- **Password**: P@ssw0rd
- **Database**: devcontainer_db

### MariaDB
- **Host**: localhost or 127.0.0.1
- **Port**: 3306
- **Username**: root
- **Password**: P@ssw0rd
- **Database**: devcontainer_db

### Redis
- **Host**: localhost or 127.0.0.1
- **Port**: 6379
- **No authentication required**

## Tips

1. **First Time Setup**: When using the extension for the first time, you'll need to pull each image before you can start containers.

2. **Docker Must Be Running**: Ensure Docker Desktop (or Docker daemon) is running before using the extension.

3. **Port Conflicts**: If you see errors when starting containers, check that the ports aren't already in use by other applications.

4. **Container Persistence**: Containers retain their state between stops and starts. Data is preserved unless you remove the container manually.

5. **Manual Container Management**: You can also manage these containers using Docker CLI or Docker Desktop if needed.

## Troubleshooting

### Extension Not Working
- Ensure Docker is installed and running
- Check that Docker CLI is accessible from your terminal (`docker --version`)
- Restart VSCode if the extension doesn't appear

### Cannot Pull Images
- Check your internet connection
- Verify Docker is running
- Check Docker Hub access (some corporate networks may block it)

### Cannot Start Containers
- Ensure the image is pulled first
- Check that ports are not already in use
- Look for error messages in the VSCode notification

### Container Shows Wrong Status
- Click the refresh icon at the top of the tree view
- Wait a few seconds after operations complete for status to update
