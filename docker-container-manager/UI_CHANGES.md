# Services Extension - UI Changes

## Activity Bar Icon
The extension now appears in the activity bar with a new "Services" icon (stacked layers representing services).

## Tree View Structure

```
SERVICES (Activity Bar Title)
│
└─ Development Services (View Title)
   │
   ├─ 📊 Databases (Expanded)
   │  │
   │  ├─ ✓ SQL Server - Running
   │  │  ├─ 🔌 Port: 1433
   │  │  ├─ 👤 Username: sa
   │  │  ├─ 🔑 Password: P@ssw0rd
   │  │  └─ 🗄️  Database: master
   │  │
   │  ├─ ○ PostgreSQL - Stopped
   │  │  ├─ 🔌 Port: 5432
   │  │  ├─ 👤 Username: postgres
   │  │  ├─ 🔑 Password: P@ssw0rd
   │  │  └─ 🗄️  Database: devcontainer_db
   │  │
   │  └─ ⬇ MariaDB - Not pulled
   │     ├─ 🔌 Port: 3306
   │     ├─ 👤 Username: root
   │     ├─ 🔑 Password: P@ssw0rd
   │     └─ 🗄️  Database: devcontainer_db
   │
   └─ 💾 Caches (Expanded)
      │
      └─ ✓ Redis - Running
         └─ 🔌 Port: 6379
```

## Key Changes from Previous Version

### 1. Extension Name
- **Before**: "Docker Container Manager"
- **After**: "Services"

### 2. Icon
- **Before**: Container icon
- **After**: Stacked layers icon (services.svg)

### 3. Tree Structure
- **Before**: Flat list of all containers
- **After**: Grouped by type (Databases, Caches)

### 4. Service Details
- **Before**: Description showed "Running on port 1433"
- **After**: Expandable items showing:
  - Port
  - Username (if applicable)
  - Password (if applicable)
  - Database (if applicable)

### 5. Adding New Services
- **Before**: Need to understand the entire extension structure
- **After**: Simply add an object to the SERVICES array with these fields:
  ```typescript
  {
      name: string,           // Internal identifier
      displayName: string,    // Display name in UI
      type: ServiceType,      // 'database' | 'cache' | 'other'
      image: string,          // Docker image
      containerName: string,  // Container name
      port: number,           // Port number
      username?: string,      // Optional username
      password?: string,      // Optional password
      database?: string,      // Optional database name
      env: object            // Environment variables for docker run
  }
  ```

## Visual Features

### Group Icons
- **Databases**: 🗄️ Database icon
- **Caches**: 💾 Server icon
- **Other Services**: 📚 Layers icon

### Service Status Icons
- **Not Pulled**: ⬇️ Cloud download icon
- **Stopped**: ○ Circle outline icon
- **Running**: ✓ Pass-filled icon (green checkmark)

### Detail Icons
- **Port**: 🔌 Port icon
- **Username**: 👤 Account icon
- **Password**: 🔑 Key icon
- **Database**: 🗄️ Database icon

## User Interaction

1. **View Groups**: Click the activity bar icon to see service groups
2. **Expand Group**: Click on "Databases" or "Caches" to see services
3. **View Details**: Click on a service name to expand and see connection details
4. **Pull Image**: Click the cloud download icon next to "Not pulled" services
5. **Start Service**: Click the play icon next to stopped services
6. **Stop Service**: Click the stop icon next to running services
7. **Refresh**: Click the refresh icon in the view title to update all statuses

## Benefits

1. **Better Organization**: Services grouped by purpose
2. **Quick Access to Details**: No need to remember connection info
3. **Easy to Extend**: Clear structure for adding new services
4. **Visual Hierarchy**: Groups → Services → Details
5. **Context-Aware Actions**: Actions only appear for applicable states
