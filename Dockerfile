ARG FROM=ubuntu:24.04
FROM ${FROM}

ARG DEBIAN_FRONTEND=noninteractive
ARG GH_RUNNER_VERSION
ARG DOCKER_COMPOSE_VERSION="1.27.4"

ENV RUNNER_NAME=""
ENV RUNNER_WORK_DIRECTORY="_work"
ENV RUNNER_TOKEN=""
ENV RUNNER_REPOSITORY_URL=""
ENV RUNNER_LABELS=""
ENV RUNNER_ALLOW_RUNASROOT=true
ENV GITHUB_ACCESS_TOKEN=""
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    efm-langserver \
    fop \
    g++ \
    gcc \
    gettext \
    git \
    iputils-ping \
    jq \
    libcurl4-openssl-dev \
    libncurses-dev \
    libssl-dev \
    libxml2-utils \
    locales \
    openssh-client \
    openssh-server \
    pipx \
    python3 \
    python3-pip \
    software-properties-common \
    sudo \
    supervisor \
    unzip \
    wget \
    xsltproc \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Locale configuration
RUN sed -i -e 's/# C.UTF-8 UTF-8/C.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true && \
    dpkg-reconfigure --frontend=noninteractive locales 2>/dev/null || true

# Install Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN git config --global user.email "brock@sam.son"
RUN git config --global user.name "Brock Samson"
RUN git config --global --add safe.directory '*'

# SSH setup
RUN mkdir -p /var/run/sshd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod 644 /etc/supervisor/conf.d/supervisord.conf

# Install Docker
RUN curl -fsSL https://get.docker.com -o- | sh && \
    rm -rf /var/lib/apt/lists/*

# Install Docker Compose
RUN curl -L -o /usr/local/bin/docker-compose \
    "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" && \
    chmod +x /usr/local/bin/docker-compose

# Install GitHub Actions Runner
RUN mkdir -p /home/runner ${AGENT_TOOLSDIRECTORY}
WORKDIR /home/runner
RUN GH_RUNNER_VERSION=${GH_RUNNER_VERSION:-$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | grep tag_name | sed -E 's/.*"v([^"]+)".*/\1/')} \
    && curl -L -O https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && tar -zxf actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && rm -f actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R root: /home/runner \
    && rm -rf /var/lib/apt/lists/*

# Install asdf + Erlang + Elixir
RUN git clone --depth=1 https://github.com/asdf-vm/asdf.git /root/.asdf --branch v0.10.0
ENV PATH="/root/.asdf/shims:/root/.asdf/bin:/root/.local/bin:./node_modules/.bin:${PATH}"
ENV EDITOR=vi
ENV KERL_BUILD_DOCS=yes

RUN asdf plugin add erlang && \
    asdf plugin add elixir && \
    asdf install erlang 28.2 && \
    asdf install elixir 1.19-otp-28 && \
    asdf global erlang 28.2 && \
    asdf global elixir 1.19-otp-28

RUN mkdir -p /home/build/ && \
    ln -s /root/.asdf/installs/elixir/1.19-otp-28/ /home/build/elixir

RUN mix local.rebar --force && \
    mix local.hex --force

# Install elixir-ls
RUN mkdir -p /tools/ && \
    curl -fLO https://github.com/elixir-lsp/elixir-ls/releases/download/v0.22.1/elixir-ls-v0.22.1.zip && \
    unzip elixir-ls-v0.22.1.zip -d /tools/elixir-ls && \
    chmod +x /tools/elixir-ls/language_server.sh && \
    ln -s /tools/elixir-ls/language_server.sh /usr/bin/elixir-ls && \
    rm elixir-ls-v0.22.1.zip

# NPM global packages
RUN npm install -g \
    typescript-language-server \
    typescript \
    vscode-json-languageserver \
    bash-language-server \
    eslint_d \
    vscode-langservers-extracted \
    @anthropic-ai/claude-code

# pipx packages
RUN pipx install pyright && \
    pipx install ruff && \
    pipx install mypy && \
    pipx install virtualenv && \
    pipx install basedpyright && \
    pipx install git+https://github.com/hauxir/planka-cli.git && \
    pipx install git+https://github.com/hauxir/metabase-cli.git && \
    pipx install git+https://github.com/hauxir/freescout-cli.git

# hcloud CLI
RUN curl -sSLO https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz && \
    tar -C /usr/local/bin --no-same-owner -xzf hcloud-linux-amd64.tar.gz hcloud && \
    rm hcloud-linux-amd64.tar.gz

# AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install gh -y && \
    rm -rf /var/lib/apt/lists/*

# ClickHouse client
RUN curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main" | tee /etc/apt/sources.list.d/clickhouse.list && \
    apt-get update && \
    apt-get install -y clickhouse-client && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/sh", "-c", "/etc/init.d/ssh start && /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf"]
