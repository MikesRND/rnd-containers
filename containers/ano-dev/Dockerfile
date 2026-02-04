# syntax=docker/dockerfile:1
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

LABEL description="ANO development container"

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

# Version info (injected at build time)
ARG CONTAINER_VERSION=dev
ARG GIT_COMMIT=unknown

ENV CONTAINER_VERSION=${CONTAINER_VERSION} \
    GIT_COMMIT=${GIT_COMMIT}

# Ensure /workspace exists (base image may not provide it)
RUN mkdir -p /workspace

# Workspace mapping: /mnt/current_folder → /workspace/<repo> symlink at container start
COPY scripts/setup_workspace_mapping.sh /setup_workspace_mapping.sh
RUN chmod +x /setup_workspace_mapping.sh && mkdir -p /etc/entrypoint.d \
    && { echo '#!/bin/bash'; \
         echo 'source /setup_workspace_mapping.sh'; \
         echo 'setup_workspace_mapping || true'; \
       } > /etc/entrypoint.d/10-workspace-mapping.sh \
    && chmod +x /etc/entrypoint.d/10-workspace-mapping.sh

# ── Python 3.11 toolchain (system 3.10 stays untouched) ───
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3.11 python3.11-venv python3.11-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Venv: vrtigo (/opt/venv/vrtigo) ──────────────────────
RUN python3.11 -m venv /opt/venv/vrtigo \
    && cd /workspace \
    && git clone --branch main --depth 1 https://github.com/MikesRND/vrtigo.git \
    && /opt/venv/vrtigo/bin/pip install --no-cache-dir -e /workspace/vrtigo/bindings/python

# ── Venv activation helpers ──────────────────────────────
# use-vrtigo: activate vrtigo venv
RUN { echo '#!/bin/bash'; \
      echo '# Usage: source use-vrtigo (or ". use-vrtigo")'; \
      echo 'source /opt/venv/vrtigo/bin/activate'; \
    } > /usr/local/bin/use-vrtigo \
    && chmod +x /usr/local/bin/use-vrtigo

# MOTD version banner (values baked at build time via double-quoted echo)
# - /etc/profile.d/ covers login shells (entrypoint su -)
# - /etc/bash.bashrc covers non-login interactive shells (docker exec bash)
# - _CONTAINER_MOTD_SHOWN guard prevents double-display
RUN { echo '# Container version banner'; \
      echo 'if [ -z "${_CONTAINER_MOTD_SHOWN:-}" ]; then'; \
      echo '    export _CONTAINER_MOTD_SHOWN=1'; \
      echo '    echo ""'; \
      echo "    echo \"  ano-dev ${CONTAINER_VERSION} (${GIT_COMMIT})\""; \
      echo '    echo ""'; \
      echo 'fi'; \
    } > /etc/profile.d/01-container-motd.sh \
    && chmod +x /etc/profile.d/01-container-motd.sh \
    && printf '\n# Container MOTD for non-login interactive shells\nif [ -n "${PS1:-}" ]; then\n    . /etc/profile.d/01-container-motd.sh\nfi\n' \
      >> /etc/bash.bashrc

WORKDIR /workspace
CMD ["bash"]
