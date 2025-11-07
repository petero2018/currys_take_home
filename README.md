# currys_take_home
take home exercise

## set up python environment

```
poetry local 3.13.7
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

Load the file whenever you run Terraform:

```
set -a
source .env
set +a
```


Environment-specific settings live under `infrastrucutre/environments/`. Two starter files are included:

- `environments/dev.tfvars`
- `environments/prod.tfvars`

Plan/apply for prod

```
cd infrastrucutre
terraform plan -var-file=environments/prod.tfvars
```

Each file can override the shared variables (project name, location, environment). Add more files (e.g., `qa.tfvars`) or use Terraform Cloud/Workspaces later—this layout keeps the repo ready for additional environments whenever you need them.


## github -> blob storage pipeline

The DLT pipeline under `src/pipelines/github_pipeline.py` ingests pull-request metadata from any list of repositories and lands the data as Parquet files in Azure Blob/ADLS. Synapse serverless SQL can read those files directly, so the PR corpus is immediately queryable without running a dedicated SQL pool.

### configuration

1. Copy `src/pipelines/.dlt/secrets.example.toml` to `src/pipelines/.dlt/secrets.toml` (gitignored) and fill in:
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
poetry install
poetry run python -m pipelines.github_pipeline
```

Each repo gets its own dataset name (`<owner>_<repo>_pull_requests`). Downstream tools such as Synapse serverless SQL or Spark can attach directly to the JSON outputs for analytics without incurring DWU costs.

You can also set the repo list and bucket URL in `src/pipelines/.dlt/config.toml`:

```
[pipeline]
repos = ["petero2018/learningPySpark", "apache/airflow"]
bucket_url = "abfss://currysprodfs@stcurrysprod.dfs.core.windows.net/github"
```

When this file exists, the pipeline reads it automatically (unless overridden by the `GITHUB_REPOS` or `DLT_BUCKET_URL` env vars), which makes managing multiple repositories and destinations easier than passing long env strings.
