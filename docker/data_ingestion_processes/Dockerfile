ARG DOCKER_REPOSITORY=python
ARG PYTHON_VERSION=3.13.7
ARG PYTHON_FLAVOUR=slim

FROM ${DOCKER_REPOSITORY}:${PYTHON_VERSION}-${PYTHON_FLAVOUR}
LABEL org.opencontainers.image.authors="oszi <osztodipeter@gmail.com>"

ARG POETRY_VERSION=2.2.1
ENV PIP_DISABLE_PIP_VERSION_CHECK=on \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_NO_INTERACTION=1 \
    PATH="$PATH:/root/.local/bin"

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git build-essential libssl-dev zlib1g-dev \
    && apt-get install -y libbz2-dev libreadline-dev libsqlite3-dev wget \
    && curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION} \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# copy poetry files first for caching
COPY data_ingestion/pyproject.toml data_ingestion/poetry.lock* data_ingestion/.python-version ./data_ingestion/

# ensure lock is consistent, then install deps
RUN poetry --directory data_ingestion lock --no-update || poetry --directory data_ingestion lock \
    && poetry --directory data_ingestion install --no-root

# copy the rest of the project
COPY data_ingestion/ ./data_ingestion/

CMD ["tail", "-f", "/dev/null"]
