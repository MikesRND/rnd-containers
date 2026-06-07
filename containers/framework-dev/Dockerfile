# syntax=docker/dockerfile:1
#
# framework-dev: final, thin developer layer for the DAQIRI-only stack.
# Built FROM framework-sdk. Adds only dev conveniences (workspace mapping,
# vrtigo, version-info banner) so editing this layer does not rebuild the
# heavy DPDK/DOCA/DAQIRI/MatX content in framework-sdk.
ARG BASE_IMAGE=framework-sdk
FROM ${BASE_IMAGE}

LABEL description="framework-dev container (DAQIRI-only, Holoscan-free)"

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

# Ensure /workspace exists (base image may not provide it)
RUN mkdir -p /workspace

# Workspace mapping: /mnt/current_folder -> /workspace/<repo> symlink at start
COPY scripts/setup_workspace_mapping.sh /setup_workspace_mapping.sh
RUN chmod +x /setup_workspace_mapping.sh && mkdir -p /etc/entrypoint.d \
    && { echo '#!/bin/bash'; \
         echo 'source /setup_workspace_mapping.sh'; \
         echo 'setup_workspace_mapping || true'; \
       } > /etc/entrypoint.d/10-workspace-mapping.sh \
    && chmod +x /etc/entrypoint.d/10-workspace-mapping.sh

# ── vrtigo (project package) + pip dependencies ──────────
# gpu-algorithms still depends on vrtigo's C++ headers + Python bindings
# even on the Holoscan-free path. Ubuntu 24.04 enforces PEP 668, so install
# into system Python with --break-system-packages (no venv in this stack).
RUN cd /workspace \
    && git clone --branch main --depth 1 https://github.com/MikesRND/vrtigo.git \
    && pip install --no-cache-dir --break-system-packages \
        -e /workspace/vrtigo/bindings/python \
        PyQt6 pyqtgraph scipy mkdocs

# use-vrtigo kept as a no-op-friendly convenience for parity with ano-dev.
RUN { echo '#!/bin/bash'; \
      echo '# vrtigo is installed into system Python in this stack; nothing to activate.'; \
      echo 'echo "vrtigo is available in the system Python environment"'; \
    } > /usr/local/bin/use-vrtigo \
    && chmod +x /usr/local/bin/use-vrtigo

# Version info (injected at build time - placed after heavy layers to avoid
# cache-busting the expensive steps above).
ARG CONTAINER_VERSION=dev
ARG GIT_COMMIT=unknown
ENV CONTAINER_VERSION=${CONTAINER_VERSION} \
    GIT_COMMIT=${GIT_COMMIT}

# ── Version-info script ──────────────────────────────────
COPY scripts/version-info.sh /usr/local/bin/version-info
RUN chmod +x /usr/local/bin/version-info \
    && version-info --live > /etc/version-info.cache

# Version banner at shell entry (login + non-login interactive shells).
RUN { echo '# Container version info banner'; \
      echo 'if [ -z "${_CONTAINER_MOTD_SHOWN:-}" ]; then'; \
      echo '    export _CONTAINER_MOTD_SHOWN=1'; \
      echo '    version-info'; \
      echo 'fi'; \
    } > /etc/profile.d/01-container-motd.sh \
    && chmod +x /etc/profile.d/01-container-motd.sh \
    && printf '\n# Container MOTD for non-login interactive shells\nif [ -n "${PS1:-}" ]; then\n    . /etc/profile.d/01-container-motd.sh\nfi\n' \
      >> /etc/bash.bashrc

WORKDIR /workspace
CMD ["bash"]
