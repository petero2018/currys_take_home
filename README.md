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


## Architecture Overview and Future Direction

This repository demonstrates a **Minimum Viable Product (MVP)** for a modular, portable data platform.  
Even though the current solution is intentionally lightweight, the architecture was designed so it can scale into a fully production-ready lakehouse.

### Modular Structure

The project is split into **three independent components**, each following clear separation of concerns:

1. **Data Ingestion** – pipelines that extract and land raw data into Azure Blob Storage  
2. **Data Transformation** – dbt + DuckDB pipelines that clean, structure and analyze data  
3. **Infrastructure** – Terraform definitions for provisioning cloud resources

This modularity is intentional. In a production setup, these three components would typically live in *three separate repositories*, each with its own CI/CD pipeline.

### Production-Ready Packaging

If this platform were promoted to production:

- each component would be **containerized**  
- each component would have its own **CI/CD workflow**, responsible for  
  - running unit and integration tests  
  - automatically deploying code into Dev and Prod environments  
- the Terraform layer would manage at least **dev** and **production** environments  
- the ingestion and transformation code is already written to be **environment-agnostic** and **portable**  
- configuration is externalised so the codebase can be reused across multiple environments with minimal changes

### Current MVP Lakehouse Implementation

Conceptually, this project follows a **lakehouse architecture**:

- The **data lake** is Azure Blob Storage (scalable, cost-efficient, simple).  
- The ingestion pipeline writes all raw data into Blob Storage.  
- DuckDB acts as the **lightweight query engine** for exploration and transformations.  
- dbt orchestrates the logical layers (Bronze → Silver → Gold), enabling reproducible transformations even at small scale.

Because the dataset is small, using heavyweight platforms (Synapse, Databricks, Snowflake, etc.) is not necessary. DuckDB provides a minimal, efficient way to transform and analyze the data locally or inside a container.

### Future Lakehouse Expansion

The platform is deliberately structured so it can be extended into a full enterprise lakehouse without redesigning ingestion:

- The ingestion pipelines **already write to Blob Storage**, meaning the lake layer is ready.  
- In the future, the business could choose any warehousing layer on top of the lake, for example:
  - **Azure Synapse**
  - **Azure Databricks**
  - **Snowflake**
  - **Any MPP (massively parallel processing) query engine**

Once the warehouse layer is selected, it can simply connect to the existing Blob Storage containers and take over the Bronze/Silver/Gold transformation layers at scale.

The current MVP demonstrates the architectural intent while keeping the solution intentionally lightweight.

### Future Orchestration Layer

In addition to the ingestion and transformation components, a production-grade data platform requires a dedicated **orchestration layer**.  
This orchestrator is responsible for scheduling, coordinating, and monitoring all data workflows across the platform.

There are multiple orchestration tools available, both open-source and fully managed. The choice depends on organisational strategy, platform maturity, and long-term scalability requirements.

#### Orchestration Options

A non-exhaustive list of options includes:

- **Apache Airflow** – open-source, highly flexible, widely adopted  
- **Managed Airflow** on Azure (MWAA equivalent)  
- **Azure Data Factory (ADF)** – serverless, managed orchestration service native to Azure  
- **Built-in orchestration capabilities of MPP platforms**, such as:
  - Azure Databricks Jobs
  - Azure Synapse Pipelines
  - Other vendor-provided schedulers

Any chosen orchestrator should meet the following criteria:

1. **Federated Control**  
   It must be able to orchestrate ingestion and transformation pipelines *across the entire data platform*, regardless of where individual workloads run.

2. **Cross-environment operability**  
   It should support Dev, Staging, and Prod environments and allow controlled promotion of workflows between them.

3. **Cross-cloud and cross-account capability**  
   As the data platform grows, it may integrate:
   - multiple Azure subscriptions  
   - additional cloud providers  
   - separate infrastructure domains  
   A suitable orchestrator must operate independently above these layers.

4. **Full-pipeline coverage**  
   The orchestrator must be capable of coordinating:
   - data ingestion pipelines  
   - transformation workflows (Bronze → Silver → Gold)  
   - table refresh jobs  
   - downstream analytics and dashboard refresh processes  

#### Strategic Considerations

The choice of orchestration system is a **strategic architectural decision**.  
It defines how the entire organisation manages data movement and transformations at scale.

A well-chosen orchestrator:

- unifies the entire platform  
- provides a central point of automation and observability  
- ensures consistent deployment and execution across environments  
- remains flexible enough to integrate future ingestion pipelines or MPP platforms

Regardless of the tool selected, the orchestration layer must operate as a **federated, platform-wide system**, independent of any single component, and capable of coordinating workflows end-to-end across the full data lifecycle.



## Testing and Deployment Strategy

In a production setup, testing and deployment would be handled through a structured CI/CD workflow, applied independently to each component of the platform (ingestion, transformation, infrastructure).

#### Testing

Each repository would run the following checks as part of its CI pipeline:

1. **Unit Tests**
   - Python unit tests for ingestion logic
   - dbt tests (schema tests, data quality tests)
   - Terraform validation (`terraform fmt`, `terraform validate`)

2. **Integration Tests**
   - For ingestion: validate end-to-end extraction → landing in Blob Storage  
   - For transformation: run dbt models against a temporary DuckDB or dev warehouse  
   - For infrastructure: Terraform plan executed in CI to confirm changes

3. **Static Checks**
   - Linting (flake8, black, sqlfluff)
   - Security scanning (Trivy / GitHub Advanced Security)
   - Dependency vulnerability checks

#### Deployment

Deployment would follow a multi-environment workflow:

1. Changes merged to `main` trigger:
   - Apply to **Dev** environment automatically
2. After validation, a manual approval deploys to **Production**
3. Infrastructure changes use Terraform with:
   - Remote state
   - CI-controlled plans and applies
4. Dockerized ingestion and transformation jobs are deployed using:
   - Airflow / ADF / Databricks Jobs (depending on orchestration choice)

The current MVP is written to be fully portable and ready for this multi-environment CI/CD setup.


## Pipeline Monitoring and Observability

In a production data platform, reliability and performance monitoring are essential.  
Several layers of monitoring would be implemented:

#### Orchestration-Level Monitoring

Regardless of the orchestrator (Airflow, ADF, Databricks Jobs), the system would provide:

- Task-level execution tracking  
- Job duration dashboards  
- Failure alerts  
- Retry visibility  
- SLA / timeout monitoring  

These provide the primary visibility into pipeline performance and stability.

#### Data Quality Monitoring

dbt provides built-in tests to monitor:

- schema consistency  
- null value violations  
- uniqueness constraints  
- referential integrity  

Failures trigger alerts in the orchestrator.

For more advanced setups, a tool like **Great Expectations** or **Monte Carlo** can be added.

#### Infrastructure & Storage Monitoring

Azure-native monitoring services:

- **Azure Monitor** (latency, errors, network throughput)
- **Storage Analytics** (Blob Storage read/write times, throttling)
- **Log Analytics + Kusto queries** to troubleshoot ingestion issues

#### Transformation Engine Monitoring

For DuckDB:
- execution logs captured by the orchestrator  
- duration metrics for dbt run steps  
- row counts and model freshness checks  

#### Optional: Central Observability Layer

For enterprise setups:

- **DataDog**, **Prometheus/Grafana**, or **Azure Application Insights**  
- end-to-end lineage tracking  
- unified alerting for ingestion, compute, and transformations  

Combined, these monitoring layers ensure visibility across ingestion → storage → transformation → serving.