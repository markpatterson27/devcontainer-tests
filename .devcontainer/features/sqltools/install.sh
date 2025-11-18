#!/bin/bash
set -e

echo "Installing mssql-tools"

# Ensure prerequisites are installed
apt-get update
apt-get install -y curl gnupg2 apt-transport-https lsb-release ca-certificates

# Get distribution info
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')

echo "Detected: ${DISTRO} ${CODENAME}"

# Add Microsoft GPG key using modern method (not deprecated apt-key)
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

# Add Microsoft repository with signed-by keyring
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/repos/microsoft-${DISTRO}-${CODENAME}-prod ${CODENAME} main" > /etc/apt/sources.list.d/microsoft.list

# Update and install
apt-get update
ACCEPT_EULA=Y apt-get install -y unixodbc-dev msodbcsql18 mssql-tools18

# Create symlinks for backwards compatibility if mssql-tools18 is installed
if [ -d "/opt/mssql-tools18" ] && [ ! -e "/opt/mssql-tools" ]; then
    ln -sf /opt/mssql-tools18 /opt/mssql-tools
fi

echo "Installing sqlpackage"
curl -sSL -o sqlpackage.zip "https://aka.ms/sqlpackage-linux"
mkdir /opt/sqlpackage
unzip sqlpackage.zip -d /opt/sqlpackage
rm sqlpackage.zip
chmod a+x /opt/sqlpackage/sqlpackage


echo "Adding sqlcmd and bcp to PATH"
MSSQL_TOOLS_PATH="/opt/mssql-tools18/bin"
if [ -d "/opt/mssql-tools/bin" ]; then
    MSSQL_TOOLS_PATH="/opt/mssql-tools/bin"
fi

echo "export PATH=\"\$PATH:${MSSQL_TOOLS_PATH}\"" >> /etc/profile.d/mssql-tools.sh
[ -f /root/.bashrc ] && echo "export PATH=\"\$PATH:${MSSQL_TOOLS_PATH}\"" >> /root/.bashrc
[ -f /home/vscode/.bashrc ] && echo "export PATH=\"\$PATH:${MSSQL_TOOLS_PATH}\"" >> /home/vscode/.bashrc

echo "Installation of mssql-tools and sqlpackage completed"

