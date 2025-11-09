FROM xemuliam/dbt:duckdb

LABEL org.opencontainers.image.authors="oszi <osztodipeter@gmail.com>"

ARG POETRY_VERSION

ENV PIP_DISABLE_PIP_VERSION_CHECK=on \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VERSION=${POETRY_VERSION} \
    PATH="$PATH:/root/.local/bin" \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# --------------------------------------------------------
# 1) Fix SSL CA cert issue for DuckDB Azure extension
# --------------------------------------------------------
RUN apt-get update && \
    apt-get install --reinstall -y ca-certificates && \
    update-ca-certificates --fresh && \
    mkdir -p /etc/pki/tls/certs && \
    ln -sf /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt

# --------------------------------------------------------
# 2) System libs + ODBC + Poetry
# --------------------------------------------------------
RUN apt-get update && \
    apt-get install -y curl git build-essential libssl-dev zlib1g-dev unzip && \
    apt-get install -y libbz2-dev libreadline-dev libsqlite3-dev wget && \
    apt-get install -y gnupg2 apt-transport-https && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg && \
    curl -fsSL https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev && \
    curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION} && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------
# 3) DuckDB CLI (AMD64) + extensions
# --------------------------------------------------------
RUN curl -L -o duckdb.zip https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip && \
    unzip duckdb.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/duckdb && \
    rm duckdb.zip && \
    duckdb -c "INSTALL httpfs;" && \
    duckdb -c "INSTALL azure;" && \
    duckdb -c "LOAD httpfs;" && \
    duckdb -c "LOAD azure;"

# --------------------------------------------------------
# 4) Auto-load .env
# --------------------------------------------------------
RUN cat <<'EOF' >/usr/local/bin/with-transform-env.sh && chmod +x /usr/local/bin/with-transform-env.sh
#!/usr/bin/env bash
set -e
ENV_FILE="/app/data_transformation/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a
fi
exec "$@"
EOF

# --------------------------------------------------------
# 5) dbt project setup
# --------------------------------------------------------
WORKDIR /app

COPY data_transformation/pyproject.toml data_transformation/poetry.lock* ./data_transformation/

ENV DBT_PROFILES_DIR=/app/data_transformation/dbt_profiles

RUN poetry --directory data_transformation lock --no-update || poetry --directory data_transformation lock
RUN poetry --directory data_transformation install --no-root

COPY data_transformation/dbt_profiles/ ./data_transformation/dbt_profiles/
COPY data_transformation/ ./data_transformation/

ENTRYPOINT ["/usr/local/bin/with-transform-env.sh"]
CMD ["bash"]