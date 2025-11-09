# currys_take_home

This repository contains a three-stage, fully containerised take-home exercise that covers infrastructure provisioning, data ingestion, and data transformation. Each stage is accessible through the project Makefile so you can work on them independently or end-to-end.

## Prerequisites

- Docker installed and running locally
- Make (for the convenience targets)
- Access to an Azure subscription with permissions to create resources

## Project stages

1. **Infrastructure** – Terraform provisions the Azure lakehouse landing zone (resource group, storage, permissions).
2. **Data ingestion** – A DLT pipeline extracts GitHub pull-request data and loads it into Azure Blob Storage.
3. **Data transformation** – dbt builds curated models on top of DuckDB connected to the blob storage.

---

## Infrastructure

The IaC module sets up the data lake foundation in Azure. The MVP stores curated data in DuckDB while keeping the lake accessible to Synapse, Databricks, or any other MPP engine you may add later.

### Configure Azure credentials

Copy `infrastructure/infra.env.sample` to `infrastructure/.env` and fill in the required environment variables:

```
ARM_CLIENT_ID=""
ARM_CLIENT_SECRET=""
ARM_TENANT_ID=""
ARM_SUBSCRIPTION_ID=""
```

These values come from an Azure Service Principal (SP). Create one with the Azure CLI (needs the `Contributor` role on the subscription):

1. Install Azure CLI if needed:  
   - macOS: `brew update && brew install azure-cli`  
   - Ubuntu/Debian: `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`  
   - Windows: `winget install --id Microsoft.AzureCLI`
2. Authenticate: `az login`
3. Capture subscription and tenant IDs:

   ```bash
   export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
   export ARM_TENANT_ID="$(az account show --query tenantId -o tsv)"
   ```

4. Create the SP and copy the output into `infrastructure/.env`:

   ```bash
   az ad sp create-for-rbac \
     --name "terraform-sp" \
     --role Contributor \
     --scopes "/subscriptions/$ARM_SUBSCRIPTION_ID"
   ```

### Provision the platform

Launch the infrastructure container:

```
make docker-infra-shell
```

Inside the shell run the standard Terraform workflow:

```
terraform init
terraform validate
terraform plan
terraform apply
```

`prod.tfvars` is used by default; pass `-var-file=dev.tfvars` (or any custom tfvars) to target another environment or region.

---

## Data ingestion

The ingestion stage lives under `data_ingestion/` and relies on DLT to read GitHub pull requests and land them in the Azure storage account you created above.

### Secrets and config

1. Copy `data_ingestion/.dlt/secrets.example.toml` to `data_ingestion/.dlt/secrets.toml` and populate:
   - `azure_storage_account_name`
   - `azure_storage_account_key`
   - `github_access_token`
2. Update `data_ingestion/.dlt/config.toml`:

   ```toml
   [pipeline]
   repos = ["org/repo", "another/repo"]
   bucket_url = "azure://<storage-account>/<container>"
   ```

### Generate a GitHub Personal Access Token (PAT)

DLT needs a PAT with `repo` scope to download repository contents. Create one via <https://github.com/settings/tokens> → **Generate new token (classic)**, name it (e.g. `dlt-github-access`), select an expiry that suits you, tick `repo`, then copy the token once displayed and paste it into `secrets.toml`.

### Run the pipeline

Start the ingestion container:

```
make docker-data-ingestion-shell
```

Inside the shell you can:

- Run tests: `poetry run pytest`
- Execute the pipeline: `poetry run python <pipeline_entrypoint>.py`
- Package and invoke the CLI variant if provided: `poetry run python <package_cli_command>`

The pipeline downloads pull-request histories for the configured repositories (last 30 days by default) and saves the JSONL output to blob storage. Additional parameters can be supplied through `config.toml`.

---

## Data transformation

The dbt project lives in `data_transformation/` and connects DuckDB to the same Azure Blob Storage bucket.

### Environment variables

Copy `data_transformation/env.secrets.sample` to `data_transformation/.env` and fill in the connection values emitted by Terraform. The file is mounted into the container and not committed to git.

### Run dbt

Provision the transformation container:

```
make docker-data-transform-shell
```

From within the shell:

- Validate connectivity: `poetry run dbt debug`
- Build models: `poetry run dbt run`
- Run tests: `poetry run dbt test`
- Or do everything in one go: `poetry run dbt build`

This stage materialises curated tables (e.g. `silver.github_pr`) in DuckDB, sourcing the raw JSON files staged by DLT.
