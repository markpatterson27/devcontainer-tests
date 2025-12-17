# Extension Builder
FROM node:24 AS extension-builder

# Install vsce
RUN npm install -g @vscode/vsce

# Copy extension source code
WORKDIR /extension
COPY ./docker-container-manager /extension

# Install dependencies and build the extension
RUN npm install && npm run compile && vsce package -o service-manager.vsix

# Final Dev Container
FROM mcr.microsoft.com/vscode/devcontainers/ubuntu:latest

# Copy the built extension from the builder stage
COPY --from=extension-builder /extension/service-manager.vsix /tmp/
