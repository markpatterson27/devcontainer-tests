# Adding New Services - Quick Guide

The Services extension is now designed to make it extremely easy to add new services. Simply add an entry to the `SERVICES` array in `src/extension.ts`.

## Example: Adding MongoDB

```typescript
const SERVICES: ServiceConfig[] = [
    // ... existing services ...
    {
        name: 'mongodb',                    // Internal identifier
        displayName: 'MongoDB',             // Name shown in UI
        type: 'database',                   // 'database', 'cache', or 'other'
        image: 'mongo:latest',              // Docker image to pull
        containerName: 'mongodb-devcontainer', // Container name
        port: 27017,                        // Port to expose
        username: 'root',                   // Username (shown in details)
        password: 'example',                // Password (masked in UI, shown in tooltip)
        database: 'admin',                  // Default database name
        env: {                              // Environment variables for docker run
            'MONGO_INITDB_ROOT_USERNAME': 'root',
            'MONGO_INITDB_ROOT_PASSWORD': 'example'
        }
    }
];
```

## Example: Adding Memcached

```typescript
{
    name: 'memcached',
    displayName: 'Memcached',
    type: 'cache',                          // Will appear under Caches group
    image: 'memcached:latest',
    containerName: 'memcached-devcontainer',
    port: 11211,
    // No username/password/database for Memcached
    env: {}
}
```

## Example: Adding RabbitMQ

```typescript
{
    name: 'rabbitmq',
    displayName: 'RabbitMQ',
    type: 'other',                          // Will appear under Other Services
    image: 'rabbitmq:3-management',
    containerName: 'rabbitmq-devcontainer',
    port: 5672,                             // AMQP port
    username: 'guest',
    password: 'guest',
    env: {
        'RABBITMQ_DEFAULT_USER': 'guest',
        'RABBITMQ_DEFAULT_PASS': 'guest'
    }
}
```

## ServiceConfig Interface

```typescript
interface ServiceConfig {
    name: string;           // Required: Internal identifier (lowercase, no spaces)
    displayName: string;    // Required: Display name in UI
    type: ServiceType;      // Required: 'database' | 'cache' | 'other'
    image: string;          // Required: Docker image (e.g., 'postgres:latest')
    containerName: string;  // Required: Docker container name
    port: number;           // Required: Port to expose
    env: object;           // Required: Environment variables for docker run
    username?: string;      // Optional: Username (displayed in details)
    password?: string;      // Optional: Password (masked in UI)
    database?: string;      // Optional: Database name (displayed in details)
}
```

## Service Types

- **`'database'`**: Groups under "Databases" with database icon
- **`'cache'`**: Groups under "Caches" with server icon
- **`'other'`**: Groups under "Other Services" with layers icon

## What Happens Automatically

When you add a new service:

1. ✅ It appears in the correct group based on `type`
2. ✅ Pull, start, stop operations work automatically
3. ✅ Status detection (not pulled, stopped, running) works
4. ✅ Service details are shown when expanded
5. ✅ Passwords are automatically masked in the UI
6. ✅ All connection info is available in one place

## Best Practices

1. **Use consistent naming**: Follow the pattern `servicename-devcontainer` for container names
2. **Document in README**: Add connection details to the main README
3. **Test locally**: Press F5 to test your new service in Extension Development Host
4. **Use official images**: Prefer official Docker images when available
5. **Keep passwords simple**: For development environments, simple passwords are fine

## Common Docker Images

- **Databases**: `postgres`, `mysql`, `mariadb`, `mongo`, `mssql/server`
- **Caches**: `redis`, `memcached`
- **Message Queues**: `rabbitmq`, `nats`
- **Search**: `elasticsearch`, `opensearch`
- **Time Series**: `influxdb`, `timescaledb`

That's it! No need to modify multiple files or understand the extension internals.
