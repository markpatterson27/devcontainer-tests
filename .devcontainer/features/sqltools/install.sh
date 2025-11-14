#!/bin/bash
echo "Installing mssql-tools"
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | (OUT=$(apt-key add - 2>&1) || echo $OUT)
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-${DISTRO}-${CODENAME}-prod ${CODENAME} main" > /etc/apt/sources.list.d/microsoft.list
apt-get update
ACCEPT_EULA=Y apt-get -y install unixodbc-dev msodbcsql18 libunwind8 mssql-tools

echo "Installing sqlpackage"
curl -sSL -o sqlpackage.zip "https://aka.ms/sqlpackage-linux"
mkdir /opt/sqlpackage
unzip sqlpackage.zip -d /opt/sqlpackage
rm sqlpackage.zip
chmod a+x /opt/sqlpackage/sqlpackage

echo "Adding sqlcmd and bcp to PATH"
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /etc/profile.d/mssql-tools.sh
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /root/.bashrc
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/vscode/.bashrc
echo "Installation of mssql-tools and sqlpackage completed"
