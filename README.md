# Deploy GCP Resources with Terraform from GitHub with Keyless Authentication

## References

- [IaC with GitHub Actions for Google Cloud Platform](https://medium.com/@irem.ertuerk/iac-with-github-actions-for-google-cloud-platform-bc28f1c4b0c7)
- [Enabling keyless authentication from GitHub Actions](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions)
- [google-github-actions/auth](https://github.com/google-github-actions/auth)
- [hashicorp/setup-terraform](https://github.com/hashicorp/setup-terraform)
- [Automate Terraform with GitHub Actions](https://learn.hashicorp.com/tutorials/terraform/github-actions)

## Setup

In Cloud Shell:

```bash
export PROJECT_ID=$(gcloud config get-value project)
export TERRAFORM_SA=terraform-provisioner
gcloud iam service-accounts create "${TERRAFORM_SA}" \
  --project "${PROJECT_ID}"

# TODO Grant the SA permissions to access Google Cloud Resources

export IDENTITY_POOL=github-identity-pool
export IDENTITY_PROVIDER=github-identity-provider
gcloud services enable iamcredentials.googleapis.com \
  --project "${PROJECT_ID}"
gcloud iam workload-identity-pools create "${IDENTITY_POOL}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub identity pool"
# TODO Override constraints/iam.workloadIdentityPoolProviders Org Policy at the project level to Allow All (or at least this one)
gcloud iam workload-identity-pools providers create-oidc "${IDENTITY_PROVIDER}"  \
   --project="${PROJECT_ID}" \
   --location="global"  \
   --workload-identity-pool="${IDENTITY_POOL}"  \
   --display-name="GitHub identity pool provider"  \
   --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud,attribute.repository=assertion.repository" \
   --issuer-uri="https://token.actions.githubusercontent.com"

export WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe "${IDENTITY_POOL}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)")
export REPO="lvaylet/terraform-in-action" # "username/name" e.g. "google/chrome"
# FIXME Should we use `attribute.repository` or `attribute.repository_owner` here? See https://stackoverflow.com/questions/71781063/gcp-workload-identity-federation-github-provider-unable-to-acquire-imperson for more details.
gcloud iam service-accounts add-iam-policy-binding "${TERRAFORM_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPO}"

export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
  --format="get(projectNumber)")
export WORKLOAD_IDENTITY_PROVIDER_ID=$(gcloud iam workload-identity-pools providers describe "${IDENTITY_PROVIDER}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${IDENTITY_POOL}" \
  --format="value(name)")
```

Then use like this, for example in `.github/workflows/terraform.yml`:

```yaml
name: Terraform
on:
  push:
    branches:
      - main
  pull_request:
jobs:
  terraform:
    name: Terraform
    runs-on: ubuntu-latest

    # Add "id-token" with the intended permissions.
    permissions:
      contents: read
      id-token: write

    steps:
    # checkout MUST come before auth
    - name: Checkout
      id: checkout
      uses: actions/checkout@v3

    - name: Authenticate to Google Cloud
      id: auth
      uses: google-github-actions/auth@v0
      with:
        workload_identity_provider: ${WORKLOAD_IDENTITY_PROVIDER_ID}
        service_account: ${TERRAFORM_SA}@${PROJECT_ID}.iam.gserviceaccount.com

    # ... further steps are automatically authenticated

    - name: Setup Terraform
      id: setup
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.2.8

    - name: Terraform Format
      id: fmt
      run: terraform fmt -check
```
