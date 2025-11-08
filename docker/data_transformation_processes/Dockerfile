# Set default versions for Python and Poetry (arguments should come before FROM)
ARG PYTHON_VERSION
ARG PYTHON_FLAVOUR
ARG DOCKER_REPOSITORY

# Start with a slim Python base image with the dynamic version
FROM ${DOCKER_REPOSITORY}:${PYTHON_VERSION}-${PYTHON_FLAVOUR}
LABEL org.opencontainers.image.authors="oszi <osztodipeter@gmail.com>"
ARG POETRY_VERSION

# Set environment variables for Poetry and add Poetry to the path
ENV PIP_DISABLE_PIP_VERSION_CHECK=on \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VERSION=${POETRY_VERSION} \
    PATH="$PATH:/root/.local/bin"

# Install system dependencies including ODBC drivers for Azure Synapse
RUN apt-get update && \
    apt-get install -y curl git build-essential libssl-dev zlib1g-dev && \
    apt-get install -y libbz2-dev libreadline-dev libsqlite3-dev wget && \
    apt-get install -y gnupg2 apt-transport-https && \
    # Install Microsoft ODBC Driver 18 for SQL Server
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev && \
    # Install Poetry
    curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION} && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy Poetry project files and install dependencies
COPY data_transformation/pyproject.toml data_transformation/poetry.lock* ./data_transformation/

ENV DBT_PROFILES_DIR=/app/data_transformation/dbt_profiles

# Ensure the lock file matches dependencies (regenerate on mismatch)
RUN poetry --directory data_transformation lock --no-update || poetry --directory data_transformation lock

# Install data transformation dependencies
RUN poetry --directory data_transformation install --no-root

# Copy the dbt profiles (credentials)
COPY data_transformation/dbt_profiles/ ./data_transformation/dbt_profiles/

# Copy the data transformation project
COPY data_transformation/ ./data_transformation/

# Default command to keep the container running (for testing)
CMD ["tail", "-f", "/dev/null"]