DOCKER ?= docker
INFRA_DIR ?= infrastructure
INFRA_IMAGE_NAME ?= currys-infra
INFRA_IMAGE_TAG ?= latest
INFRA_IMAGE ?= $(INFRA_IMAGE_NAME):$(INFRA_IMAGE_TAG)
DOCKERFILE_INFRA ?= docker/infrastructure_processes/Dockerfile
INFRA_ENV_FILE ?= $(INFRA_DIR)/.env
TF_VARS_FILE ?= environments/prod.tfvars
TF_PLAN_ARGS ?=
TF_APPLY_ARGS ?=
TF_DESTROY_ARGS ?=

DATA_INGESTION_DIR ?= data_ingestion
DOCKER_REPOSITORY ?= python
PYTHON_VERSION ?= 3.13.7
PYTHON_FLAVOUR ?= slim
POETRY_VERSION ?= 2.2.1
GIT_VERSION := $(shell git -C . describe --tags 2> /dev/null || git -C . rev-parse --short HEAD)
DOCKER_DATA_INGESTION_IMAGE_NAME ?= currys-data-ingestion
DOCKER_DATA_INGESTION_IMAGE_TAG ?= $(PYTHON_VERSION)-$(GIT_VERSION)
DOCKER_DATA_INGESTION_IMAGE ?= $(DOCKER_REPOSITORY)/$(DOCKER_DATA_INGESTION_IMAGE_NAME):$(DOCKER_DATA_INGESTION_IMAGE_TAG)

.DEFAULT_GOAL := help
SHELL := bash

.PHONY: help docker-infra-build docker-infra-shell docker-data-ingestion-build docker-data-ingestion-shell

help:
	@echo "Infrastructure targets:"
	@echo "  docker-infra-build   Build the Terraform/Azure CLI helper image"
	@echo "  docker-infra-shell   Start a shell inside the helper image (bind-mount repo)"
	@echo ""
	@echo "Data ingestion targets:"
	@echo "  docker-data-ingestion-build   Build the Poetry-based data ingestion image"
	@echo "  docker-data-ingestion-shell   Open a shell inside the data ingestion image"


docker-infra-build:
	@echo "Building image $(INFRA_IMAGE) using $(DOCKERFILE_INFRA)"
	$(DOCKER) build -f $(DOCKERFILE_INFRA) -t $(INFRA_IMAGE) .

# Helper to run Docker commands with optional env-file
define docker_run
	env_file_flag=$$( [ -f $(INFRA_ENV_FILE) ] && printf -- "--env-file $(INFRA_ENV_FILE)" ); \
	$(DOCKER) run --rm -it $$env_file_flag \
		-v $(CURDIR):/workspace \
		-w /workspace/$(INFRA_DIR) \
		$(INFRA_IMAGE) bash -lc "$$1"
endef

define docker_run_shell
	env_file_flag=$$( [ -f $(INFRA_ENV_FILE) ] && printf -- "--env-file $(INFRA_ENV_FILE)" ); \
	$(DOCKER) run --rm -it $$env_file_flag \
		-v $(CURDIR):/workspace \
		-w /workspace/$(INFRA_DIR) \
		$(INFRA_IMAGE) bash
endef


docker-infra-shell: docker-infra-build
	@echo "Launching shell in $(INFRA_IMAGE)"
	@$(call docker_run_shell)

docker-data-ingestion-build:
	@echo "Building data ingestion image $(DOCKER_DATA_INGESTION_IMAGE)"
	$(DOCKER) build \
		--file docker/data_ingestion_processes/Dockerfile \
		--build-arg DOCKER_REPOSITORY=$(DOCKER_REPOSITORY) \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
		--build-arg PYTHON_FLAVOUR=$(PYTHON_FLAVOUR) \
		--build-arg POETRY_VERSION=$(POETRY_VERSION) \
		--tag $(DOCKER_DATA_INGESTION_IMAGE) \
		.

docker-data-ingestion-shell: docker-data-ingestion-build
	@echo "Launching data ingestion shell from $(DOCKER_DATA_INGESTION_IMAGE)"
	$(DOCKER) run --rm -it \
		-v $(CURDIR):/app \
		-w /app/$(DATA_INGESTION_DIR) \
		$(DOCKER_DATA_INGESTION_IMAGE) \
		bash
