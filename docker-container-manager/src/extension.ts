import * as vscode from 'vscode';
import { execFile } from 'child_process';
import { promisify } from 'util';

const execFileAsync = promisify(execFile);

export function activate(context: vscode.ExtensionContext) {
    console.log('Services extension is now active');

    const servicesProvider = new ServicesProvider();
    vscode.window.registerTreeDataProvider('dockerContainerManager', servicesProvider);

    context.subscriptions.push(
        vscode.commands.registerCommand('dockerContainerManager.refresh', () => {
            servicesProvider.refresh();
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('dockerContainerManager.pullImage', async (item: ServiceItem) => {
            await pullImage(item, servicesProvider);
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('dockerContainerManager.startContainer', async (item: ServiceItem) => {
            await startService(item, servicesProvider);
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('dockerContainerManager.stopContainer', async (item: ServiceItem) => {
            await stopService(item, servicesProvider);
        })
    );
}

export function deactivate() {}

type ServiceType = 'database' | 'cache' | 'other';

interface ServiceConfig {
    name: string;
    displayName: string;
    type: ServiceType;
    image: string;
    containerName: string;
    port: number;
    env: { [key: string]: string };
    // Connection details
    username?: string;
    password?: string;
    database?: string;
}

// Define services in a simple array - easy to add new services
const SERVICES: ServiceConfig[] = [
    {
        name: 'mssql',
        displayName: 'SQL Server',
        type: 'database',
        image: 'mcr.microsoft.com/mssql/server:2019-latest',
        containerName: 'mssql-devcontainer',
        port: 1433,
        username: 'sa',
        password: 'P@ssw0rd',
        database: 'master',
        env: {
            'ACCEPT_EULA': 'Y',
            'SA_PASSWORD': 'P@ssw0rd'
        }
    },
    {
        name: 'postgres',
        displayName: 'PostgreSQL',
        type: 'database',
        image: 'postgres:latest',
        containerName: 'postgres-devcontainer',
        port: 5432,
        username: 'postgres',
        password: 'P@ssw0rd',
        database: 'devcontainer_db',
        env: {
            'POSTGRES_PASSWORD': 'P@ssw0rd',
            'POSTGRES_DB': 'devcontainer_db'
        }
    },
    {
        name: 'mariadb',
        displayName: 'MariaDB',
        type: 'database',
        image: 'mariadb:latest',
        containerName: 'mariadb-devcontainer',
        port: 3306,
        username: 'root',
        password: 'P@ssw0rd',
        database: 'devcontainer_db',
        env: {
            'MYSQL_ROOT_PASSWORD': 'P@ssw0rd',
            'MYSQL_DATABASE': 'devcontainer_db'
        }
    },
    {
        name: 'redis',
        displayName: 'Redis',
        type: 'cache',
        image: 'redis:latest',
        containerName: 'redis-devcontainer',
        port: 6379,
        env: {}
    }
];

type TreeNode = ServiceGroupItem | ServiceItem | ServiceDetailItem;

class ServicesProvider implements vscode.TreeDataProvider<TreeNode> {
    private _onDidChangeTreeData: vscode.EventEmitter<TreeNode | undefined | null | void> = new vscode.EventEmitter<TreeNode | undefined | null | void>();
    readonly onDidChangeTreeData: vscode.Event<TreeNode | undefined | null | void> = this._onDidChangeTreeData.event;

    refresh(): void {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(element: TreeNode): vscode.TreeItem {
        return element;
    }

    async getChildren(element?: TreeNode): Promise<TreeNode[]> {
        if (!element) {
            // Root level - return groups
            return this.getServiceGroups();
        } else if (element instanceof ServiceGroupItem) {
            // Group level - return services in this group
            return this.getServicesInGroup(element.type);
        } else if (element instanceof ServiceItem) {
            // Service level - return service details
            return this.getServiceDetails(element);
        }
        return [];
    }

    private getServiceGroups(): ServiceGroupItem[] {
        const groups = new Map<ServiceType, string>();
        groups.set('database', 'Databases');
        groups.set('cache', 'Caches');
        groups.set('other', 'Other Services');

        const result: ServiceGroupItem[] = [];
        for (const service of SERVICES) {
            if (!result.find(g => g.type === service.type)) {
                const groupName = groups.get(service.type) || 'Other Services';
                result.push(new ServiceGroupItem(groupName, service.type));
            }
        }
        return result;
    }

    private async getServicesInGroup(type: ServiceType): Promise<ServiceItem[]> {
        const items: ServiceItem[] = [];
        for (const config of SERVICES.filter(s => s.type === type)) {
            const status = await getServiceStatus(config);
            items.push(new ServiceItem(config, status));
        }
        return items;
    }

    private getServiceDetails(service: ServiceItem): ServiceDetailItem[] {
        const details: ServiceDetailItem[] = [];
        
        // Port
        details.push(new ServiceDetailItem('Port', service.config.port.toString(), 'port'));
        
        // Username
        if (service.config.username) {
            details.push(new ServiceDetailItem('Username', service.config.username, 'account'));
        }
        
        // Password
        if (service.config.password) {
            details.push(new ServiceDetailItem('Password', service.config.password, 'key'));
        }
        
        // Database
        if (service.config.database) {
            details.push(new ServiceDetailItem('Database', service.config.database, 'database'));
        }
        
        return details;
    }
}

class ServiceGroupItem extends vscode.TreeItem {
    constructor(
        public readonly label: string,
        public readonly type: ServiceType
    ) {
        super(label, vscode.TreeItemCollapsibleState.Expanded);
        this.contextValue = 'service-group';
        this.iconPath = new vscode.ThemeIcon(this.getIcon());
    }

    private getIcon(): string {
        switch (this.type) {
            case 'database':
                return 'database';
            case 'cache':
                return 'server';
            default:
                return 'layers';
        }
    }
}

type ServiceStatus = 'notpulled' | 'stopped' | 'running';

class ServiceItem extends vscode.TreeItem {
    constructor(
        public readonly config: ServiceConfig,
        public readonly status: ServiceStatus
    ) {
        super(config.displayName, vscode.TreeItemCollapsibleState.Collapsed);
        
        this.tooltip = `${config.displayName} (${config.image})`;
        this.description = this.getDescription();
        this.contextValue = `service-${status}`;
        this.iconPath = new vscode.ThemeIcon(this.getIcon());
    }

    private getDescription(): string {
        switch (this.status) {
            case 'notpulled':
                return 'Not pulled';
            case 'stopped':
                return 'Stopped';
            case 'running':
                return 'Running';
            default:
                return '';
        }
    }

    private getIcon(): string {
        switch (this.status) {
            case 'notpulled':
                return 'cloud-download';
            case 'stopped':
                return 'circle-outline';
            case 'running':
                return 'pass-filled';
            default:
                return 'circle-outline';
        }
    }
}

class ServiceDetailItem extends vscode.TreeItem {
    constructor(
        public readonly label: string,
        public readonly value: string,
        public readonly iconName: string
    ) {
        super(`${label}: ${value}`, vscode.TreeItemCollapsibleState.None);
        this.contextValue = 'service-detail';
        this.iconPath = new vscode.ThemeIcon(iconName);
        this.tooltip = `${label}: ${value}`;
    }
}

async function getServiceStatus(config: ServiceConfig): Promise<ServiceStatus> {
    try {
        // Check if image exists - use execFile for safer execution
        const { stdout: imagesOutput } = await execFileAsync('docker', ['images', '-q', config.image]);
        if (!imagesOutput.trim()) {
            return 'notpulled';
        }

        // Check if container is running
        const { stdout: psOutput } = await execFileAsync('docker', ['ps', '-q', '-f', `name=${config.containerName}`]);
        if (psOutput.trim()) {
            return 'running';
        }

        // Check if container exists but is stopped
        const { stdout: psAllOutput } = await execFileAsync('docker', ['ps', '-aq', '-f', `name=${config.containerName}`]);
        if (psAllOutput.trim()) {
            return 'stopped';
        }

        return 'stopped';
    } catch (error) {
        console.error('Error checking service status:', error);
        return 'stopped';
    }
}

async function pullImage(item: ServiceItem, provider: ServicesProvider) {
    await vscode.window.withProgress(
        {
            location: vscode.ProgressLocation.Notification,
            title: `Pulling ${item.config.displayName} image...`,
            cancellable: false
        },
        async () => {
            try {
                await execFileAsync('docker', ['pull', item.config.image]);
                vscode.window.showInformationMessage(`Successfully pulled ${item.config.displayName} image`);
                provider.refresh();
            } catch (error) {
                vscode.window.showErrorMessage(`Failed to pull ${item.config.displayName} image: ${error}`);
            }
        }
    );
}

async function startService(item: ServiceItem, provider: ServicesProvider) {
    await vscode.window.withProgress(
        {
            location: vscode.ProgressLocation.Notification,
            title: `Starting ${item.config.displayName}...`,
            cancellable: false
        },
        async () => {
            try {
                // Check if container exists
                const { stdout: psAllOutput } = await execFileAsync('docker', ['ps', '-aq', '-f', `name=${item.config.containerName}`]);
                
                if (psAllOutput.trim()) {
                    // Container exists, just start it
                    await execFileAsync('docker', ['start', item.config.containerName]);
                } else {
                    // Create and start new container
                    const dockerArgs = ['run', '--name', item.config.containerName];
                    
                    // Add environment variables
                    for (const [key, value] of Object.entries(item.config.env)) {
                        dockerArgs.push('-e', `${key}=${value}`);
                    }
                    
                    // Add port mapping and image
                    dockerArgs.push('-p', `${item.config.port}:${item.config.port}`, '-d', item.config.image);
                    
                    await execFileAsync('docker', dockerArgs);
                }
                
                vscode.window.showInformationMessage(`${item.config.displayName} started successfully`);
                provider.refresh();
            } catch (error) {
                vscode.window.showErrorMessage(`Failed to start ${item.config.displayName}: ${error}`);
            }
        }
    );
}

async function stopService(item: ServiceItem, provider: ServicesProvider) {
    await vscode.window.withProgress(
        {
            location: vscode.ProgressLocation.Notification,
            title: `Stopping ${item.config.displayName}...`,
            cancellable: false
        },
        async () => {
            try {
                await execFileAsync('docker', ['stop', item.config.containerName]);
                vscode.window.showInformationMessage(`${item.config.displayName} stopped successfully`);
                provider.refresh();
            } catch (error) {
                vscode.window.showErrorMessage(`Failed to stop ${item.config.displayName}: ${error}`);
            }
        }
    );
}
