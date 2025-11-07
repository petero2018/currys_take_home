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

Create a service principal for Terraform so it can authenticate non‑interactively

az ad sp create-for-rbac \
  --name tf-currys \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth
```

Load the file whenever you run Terraform:

```
set -a
source .env
set +a
```

## terraform variables & cost toggles

Put your Terraform-specific values into the same `.env` so they export automatically when you run the `set -a; source .env; set +a` block:

```
TF_VAR_synapse_sql_admin_password="<generated-strong-password>"
TF_VAR_project_name="currys"
TF_VAR_location="uksouth"
TF_VAR_environment="dev"
TF_VAR_create_synapse_sql_pool="false"  # switch to true only when you really need DW capacity
TF_VAR_synapse_sql_pool_sku="DW100c"
```

This keeps secrets outside git while letting Terraform pick up the inputs through environment variables, and it defaults to the lowest-cost Synapse setup (workspace only, no SQL pool).


Environment-specific settings live under `infrastrucutre/environments/`. Two starter files are included:

- `environments/dev.tfvars`
- `environments/prod.tfvars`

Plan/apply for prod

```
cd infrastrucutre
export TF_VAR_environment="prod"
terraform plan -var-file=environments/prod.tfvars
```

Each file can override the shared variables (project name, location, environment). Add more files (e.g., `qa.tfvars`) or use Terraform Cloud/Workspaces later—this layout keeps the repo ready for additional environments whenever you need them.

## pending documentation

More detailed Terraform, data-pipeline, and Synapse usage notes will be added later as the exercise evolves.
