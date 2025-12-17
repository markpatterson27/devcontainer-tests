# Services Manager

A VSCode extension that makes it easy to manage development services including databases and caches.

## Features

- **Visual Service Management**: View services organized by type (Relational Databases, Caches) in a dedicated sidebar
- **Service Details**: Expand each service to see connection details including port, username, password, and database name
- **One-Click Operations**: Pull images, start and stop services with a single click
- **Easy to Extend**: Simply add new services to the configuration array
- **Supported Services**:
  - **Relational Databases**: SQL Server (2019), PostgreSQL (latest), MariaDB (latest)
  - **Caches**: Redis (latest)

## Usage

1. Open the Services view from the activity bar
2. Read the welcome message at the top of the view for quick instructions
3. Services are grouped by type (Relational Databases, Caches)
4. Expand a group to see all services of that type
5. For services not yet pulled, click the cloud download icon to pull the image
6. Once pulled, click the play icon to start the service
7. Expand a running service to see connection details
8. Click the stop icon to stop a running service

The welcome message provides quick-start guidance:
- Expand service groups to browse available services
- Pull images before first use
- Start/stop services as needed
- View connection details by expanding services

## Service Details

Each service shows the following connection details when expanded:

### SQL Server
- **Port**: 1433
- **Username**: sa
- **Password**: P@ssw0rd
- **Database**: master
- **Container Name**: mssql-devcontainer

### PostgreSQL
- **Port**: 5432
- **Username**: postgres
- **Password**: P@ssw0rd
- **Database**: devcontainer_db
- **Container Name**: postgres-devcontainer

### MariaDB
- **Port**: 3306
- **Username**: root
- **Password**: P@ssw0rd
- **Database**: devcontainer_db
- **Container Name**: mariadb-devcontainer

### Redis
- **Port**: 6379
- **Container Name**: redis-devcontainer

## Adding New Services

To add a new service, simply add an entry to the `SERVICES` array in `src/extension.ts`:

```typescript
{
    name: 'mongodb',
    displayName: 'MongoDB',
    type: 'database', // or 'cache' or 'other'
    image: 'mongo:latest',
    containerName: 'mongodb-devcontainer',
    port: 27017,
    username: 'root',
    password: 'example',
    database: 'admin',
    env: {
        'MONGO_INITDB_ROOT_USERNAME': 'root',
        'MONGO_INITDB_ROOT_PASSWORD': 'example'
    }
}
```

## Requirements

- Docker must be installed and running on your system
- Docker daemon must be accessible from the command line

## Security Considerations

**⚠️ Development Use Only**: This extension is designed for local development environments. The services use default passwords (`P@ssw0rd`) for convenience during development.

**Important Security Notes**:
- Do not use these services in production environments
- Do not expose these services to public networks
- The default passwords are intended for local development only
- For production use, always configure secure passwords and proper authentication

## Extension Settings

This extension does not add any VS Code settings.

## Known Issues

None at this time.

## Release Notes

### 0.0.1

Initial release of Services Manager

- Support for SQL Server, PostgreSQL, MariaDB, and Redis
- Pull, start, and stop operations
- Visual status indicators
- Service grouping by type
- Service detail display (port, username, password, database)
- Easy to extend with new services
