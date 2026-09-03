FROM node:trixie-slim

RUN apt-get update && apt-get install -y \
    build-essential \
    procps \
    curl \
    file \
    git \
    sudo \
    openjdk-21-jdk \
    ca-certificates \
    gnupg \
    jq \
    python3 \
    yq \
    age \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI via official Docker repository
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "Types: deb\n\
URIs: https://download.docker.com/linux/debian\n\
Suites: trixie\n\
Components: stable\n\
Signed-By: /etc/apt/keyrings/docker.asc" > /etc/apt/sources.list.d/docker.sources && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create Homebrew directory structure and give ownership to node user
# (Homebrew on Linux is hardcoded to install to /home/linuxbrew/.linuxbrew)
# We reuse the existing 'node' user (UID 1000) from the base image
RUN mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R node:node /home/linuxbrew

# Switch to node user for Homebrew installation (Homebrew refuses to run as root)
USER node
WORKDIR /home/node
ENV HOME=/home/node

# Install Homebrew non-interactively
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to shell profile
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/node/.bashrc

RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && \
    brew trust anomalyco/tap && \
    brew install anomalyco/tap/opencode opentofu gh forgejo-cli kubectl sops

# Set up environment for runtime
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

# Container runs as node user (non-root)
USER node
WORKDIR /home/node

# Copy and set up entrypoint script and credential helper
COPY entrypoint.sh /entrypoint.sh
COPY forgejo-credential-helper.sh /home/node/.config/forgejo-credential-helper.sh

# Pre-create application directories to ensure they have correct ownership
# when Docker mounts volumes or when the app tries to create subdirectories.
# Otherwise Docker will do the same on mounting volumes to these dirs, creating
# parent dirs as root in the process.
USER root
RUN mkdir -p /home/node/.local/share/opencode \
             /home/node/.config/opencode \
             /home/node/.cache/opencode \
             /home/node/projects && \
    chown -R node:node /home/node && \
    chmod +x /entrypoint.sh && \
    chmod +x /home/node/.config/forgejo-credential-helper.sh
USER node

ENTRYPOINT ["/entrypoint.sh"]
