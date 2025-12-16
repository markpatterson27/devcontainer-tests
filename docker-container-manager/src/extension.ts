import * as vscode from 'vscode';
import { execFile } from 'child_process';
import { promisify } from 'util';

const execFileAsync = promisify(execFile);

export function activate(context: vscode.ExtensionContext) {
    console.log('Docker Container Manager extension is now active');

    const containerProvider = new ContainerProvider();
    vscode.window.registerTreeDataProvider('dockerContainerManager', containerProvider);

    context.subscriptions.push(
        vscode.commands.registerCommand('dockerContainerManager.refresh', () => {
            containerProvider.refresh();
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('dockerContainerManager.pullImage', async (item: ContainerItem) => {
            await pullImage(item, containerProvider);
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('dockerContainerManager.startContainer', async (item: ContainerItem) => {
            await startContainer(item, containerProvider);
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('dockerContainerManager.stopContainer', async (item: ContainerItem) => {
            await stopContainer(item, containerProvider);
        })
    );
}

export function deactivate() {}

interface ContainerConfig {
    name: string;
    displayName: string;
    image: string;
    containerName: string;
    port: number;
    env: { [key: string]: string };
}

const CONTAINERS: ContainerConfig[] = [
    {
        name: 'mssql',
        displayName: 'SQL Server',
        image: 'mcr.microsoft.com/mssql/server:2019-latest',
        containerName: 'mssql-devcontainer',
        port: 1433,
        env: {
            'ACCEPT_EULA': 'Y',
            'SA_PASSWORD': 'P@ssw0rd'
        }
    },
    {
        name: 'postgres',
        displayName: 'PostgreSQL',
        image: 'postgres:latest',
        containerName: 'postgres-devcontainer',
        port: 5432,
        env: {
            'POSTGRES_PASSWORD': 'P@ssw0rd',
            'POSTGRES_DB': 'devcontainer_db'
        }
    },
    {
        name: 'mariadb',
        displayName: 'MariaDB',
        image: 'mariadb:latest',
        containerName: 'mariadb-devcontainer',
        port: 3306,
        env: {
            'MYSQL_ROOT_PASSWORD': 'P@ssw0rd',
            'MYSQL_DATABASE': 'devcontainer_db'
        }
    },
    {
        name: 'redis',
        displayName: 'Redis',
        image: 'redis:latest',
        containerName: 'redis-devcontainer',
        port: 6379,
        env: {}
    }
];

class ContainerProvider implements vscode.TreeDataProvider<ContainerItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<ContainerItem | undefined | null | void> = new vscode.EventEmitter<ContainerItem | undefined | null | void>();
    readonly onDidChangeTreeData: vscode.Event<ContainerItem | undefined | null | void> = this._onDidChangeTreeData.event;

    refresh(): void {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(element: ContainerItem): vscode.TreeItem {
        return element;
    }

    async getChildren(element?: ContainerItem): Promise<ContainerItem[]> {
        if (!element) {
            const items: ContainerItem[] = [];
            for (const config of CONTAINERS) {
                const status = await getContainerStatus(config);
                items.push(new ContainerItem(config, status));
            }
            return items;
        }
        return [];
    }
}

type ContainerStatus = 'notpulled' | 'stopped' | 'running';

class ContainerItem extends vscode.TreeItem {
    constructor(
        public readonly config: ContainerConfig,
        public readonly status: ContainerStatus
    ) {
        super(config.displayName, vscode.TreeItemCollapsibleState.None);
        
        this.tooltip = `${config.displayName} (${config.image})`;
        this.description = this.getDescription();
        this.contextValue = `container-${status}`;
        this.iconPath = new vscode.ThemeIcon(this.getIcon());
    }

    private getDescription(): string {
        switch (this.status) {
            case 'notpulled':
                return 'Image not pulled';
            case 'stopped':
                return 'Stopped';
            case 'running':
                return `Running on port ${this.config.port}`;
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
                return 'circle-filled';
            default:
                return 'circle-outline';
        }
    }
}

async function getContainerStatus(config: ContainerConfig): Promise<ContainerStatus> {
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
        console.error('Error checking container status:', error);
        return 'stopped';
    }
}

async function pullImage(item: ContainerItem, provider: ContainerProvider) {
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

async function startContainer(item: ContainerItem, provider: ContainerProvider) {
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
                
                vscode.window.showInformationMessage(`${item.config.displayName} started successfully on port ${item.config.port}`);
                provider.refresh();
            } catch (error) {
                vscode.window.showErrorMessage(`Failed to start ${item.config.displayName}: ${error}`);
            }
        }
    );
}

async function stopContainer(item: ContainerItem, provider: ContainerProvider) {
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
