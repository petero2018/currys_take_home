# currys_take_home
take home exercise

## set up python environment

#### pyenv
```
pyenv versions
pyenv install -l
pyenv install 3.13.7 
pyenv local 3.13.7
```

#### poetry env
```
poetry env list --full-path
poetry env use 3.13.7  Activates or creates a new virtualenv for the current project.
eval $(poetry env activate) Activates virtualenv
which python 
```


## setup terraform

```
brew install azure-cli      -- install
az login choose             -- the subscription tied to your account
az account show             -- verify you’re on the right subscription ID
export SUBSCRIPTION_ID=$(az account show --query id -o tsv) -- assign subscription id to env var
```

Before running Terraform copy `infrastructure/infra.env.sample` (or `infra.env.example` with realistic values) to `infrastructure/.env`, fill in your Azure service principal (`ARM_*`) and `TF_VAR_*` entries, and the Make targets will pick them up automatically via `--env-file`.


Environment-specific settings live under `infrastructure/environments/`. Two starter files are included:

- `environments/dev.tfvars`
- `environments/prod.tfvars`

Plan/apply for prod

```
cd infrastructure
terraform plan -var-file=environments/prod.tfvars
```

Each file can override the shared variables (project name, location, environment). Add more files (e.g., `qa.tfvars`) or use Terraform Cloud/Workspaces later—this layout keeps the repo ready for additional environments whenever you need them.

### run terraform via docker

A helper image + Makefile let you run Terraform (for resource group + storage provisioning) in a container (no local install). Synapse itself is provisioned manually in the Azure portal.

```
# build the helper image (Terraform + Azure CLI)
make docker-infra-build

# start a shell with all env vars loaded; run terraform init/plan/apply manually
make docker-infra-shell
```

Once inside the shell, run the usual Terraform commands (`terraform init`, `terraform plan -var-file=...`, etc.). By default the Makefile looks for `infrastructure/.env`; copy `infra.env.sample` to `.env`, fill it in, and the vars will be passed via `--env-file` so Terraform can authenticate. Override `INFRA_ENV_FILE` when invoking `make` if your credentials live elsewhere.


## github -> blob storage pipeline

The DLT pipeline under `data_ingestion/github_pipeline.py` ingests pull-request metadata from any list of repositories and lands the data as JSONL files in Azure Blob/ADLS. Synapse serverless SQL can read those files directly, so the PR corpus is immediately queryable without running a dedicated SQL pool.

### configuration

1. Copy `data_ingestion/.dlt/secrets.example.toml` to `data_ingestion/.dlt/secrets.toml` (gitignored) and fill in:
   - `sources.github.access_token` – GitHub PAT with `repo` scope.
   - `destination.filesystem.credentials.account_name` and `account_key` – storage account the pipeline writes to.

Optional
2. Export runtime env vars before running the pipeline:

```
export DLT_BUCKET_URL="abfss://currysprodfs@stcurrysprod.dfs.core.windows.net/github"  # optional override, otherwise use config
export GITHUB_REPOS="dlt-hub/dlt,apache/airflow"   # optional override, otherwise use config
export GITHUB_MAX_ITEMS=200                         # optional limit for quick tests
```

### run locally

```
poetry --directory data_ingestion install
poetry --directory data_ingestion run python github_pipeline.py
```

Each repo gets its own dataset name (`<owner>_<repo>_pull_requests`). Downstream tools such as Synapse serverless SQL or Spark can attach directly to the JSON outputs for analytics without incurring DWU costs.

You can also set the repo list and bucket URL in `data_ingestion/.dlt/config.toml`:

```
[pipeline]
repos = ["petero2018/learningPySpark", "apache/airflow"]
bucket_url = "abfss://currysprodfs@stcurrysprod.dfs.core.windows.net/github"
```

When this file exists, the pipeline reads it automatically (unless overridden by the `GITHUB_REPOS` or `DLT_BUCKET_URL` env vars), which makes managing multiple repositories and destinations easier than passing long env strings.

### run inside docker

If you prefer containerised execution, use the Make targets:

```
make docker-data-ingestion-build
make docker-data-ingestion-shell
```

The shell drops you into `/app/data_ingestion` inside the Poetry image so you can run `poetry run python github_pipeline.py` (or any other commands) without installing dependencies locally.
