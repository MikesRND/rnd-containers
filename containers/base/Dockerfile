# syntax=docker/dockerfile:1
ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

LABEL maintainer="mikesrnd"
LABEL layer="0-base"

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

# ── Certificates ────────────────────────────────────────────
COPY certs/ /tmp/certs/
RUN if [ -n "$(find /tmp/certs -name '*.crt' -o -name '*.pem' -o -name '*.cer' 2>/dev/null | head -1)" ]; then \
        if ! command -v update-ca-certificates &>/dev/null; then \
            apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*; \
        fi && \
        mkdir -p /usr/local/share/ca-certificates && \
        find /tmp/certs \( -name '*.crt' -o -name '*.pem' -o -name '*.cer' \) -exec cp {} /usr/local/share/ca-certificates/ \; && \
        update-ca-certificates && \
        echo "Certificates installed: $(find /tmp/certs \( -name '*.crt' -o -name '*.pem' -o -name '*.cer' \) | wc -l)"; \
    else \
        echo "No certificates to install"; \
    fi && \
    rm -rf /tmp/certs

ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

# ── Entrypoint + drop-in hook directory ────────────────────
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && mkdir -p /etc/entrypoint.d

RUN if ! command -v sudo &>/dev/null; then \
        apt-get update && apt-get install -y --no-install-recommends sudo && rm -rf /var/lib/apt/lists/*; \
    fi

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
