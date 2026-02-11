# syntax=docker/dockerfile:1
ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

LABEL description="ANO development container"

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

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

# ── Vrtigo (project package) + pip dependencies ──────────
# Venv is inherited from Layer 2 (ano-tools) with VIRTUAL_ENV + PATH set.
RUN cd /workspace \
    && git clone --branch main --depth 1 https://github.com/MikesRND/vrtigo.git \
    && pip install --no-cache-dir \
        -e /workspace/vrtigo/bindings/python \
        PyQt6 pyqtgraph scipy mkdocs

# ── Venv activation helpers ──────────────────────────────
# use-vrtigo: activate vrtigo venv
RUN { echo '#!/bin/bash'; \
      echo '# Usage: source use-vrtigo (or ". use-vrtigo")'; \
      echo 'source /opt/venv/vrtigo/bin/activate'; \
    } > /usr/local/bin/use-vrtigo \
    && chmod +x /usr/local/bin/use-vrtigo

# ── Version-info script  ──────────────────────────────
COPY scripts/version-info.sh /usr/local/bin/version-info
RUN chmod +x /usr/local/bin/version-info \
    && version-info --live > /etc/version-info.cache

# Version banner (calls version-info at shell entry)
# - /etc/profile.d/ covers login shells (entrypoint su -)
# - /etc/bash.bashrc covers non-login interactive shells (docker exec bash)
# - _CONTAINER_MOTD_SHOWN guard prevents double-display
RUN { echo '# Container version info banner'; \
      echo 'if [ -z "${_CONTAINER_MOTD_SHOWN:-}" ]; then'; \
      echo '    export _CONTAINER_MOTD_SHOWN=1'; \
      echo '    version-info'; \
      echo 'fi'; \
    } > /etc/profile.d/01-container-motd.sh \
    && chmod +x /etc/profile.d/01-container-motd.sh \
    && printf '\n# Container MOTD for non-login interactive shells\nif [ -n "${PS1:-}" ]; then\n    . /etc/profile.d/01-container-motd.sh\nfi\n' \
      >> /etc/bash.bashrc

# Version info (injected at build time – placed late to avoid cache-busting heavy layers)
ARG CONTAINER_VERSION=dev
ARG GIT_COMMIT=unknown
ENV CONTAINER_VERSION=${CONTAINER_VERSION} \
    GIT_COMMIT=${GIT_COMMIT}

WORKDIR /workspace
CMD ["bash"]
