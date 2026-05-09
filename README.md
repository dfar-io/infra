# infra

Terraform infrastructure project with remote state and credential-based applies.

## What this project sets up

- Terraform project structure with pinned versions
- GCP provider configuration
- Remote state via GCS backend (configured in code)
- A small starter resource (`random_pet`) so `plan/apply` produces a real change

## Prerequisites

- Terraform v1.8+
- GCP credentials configured locally (for example via `gcloud auth application-default login`)
- An existing GCS bucket for Terraform state

If you want a ready-to-use environment, consider creating a GitHub Codespace for this repository.

## 0) Set your GCP identity

Use your existing credential flow. Example with Application Default Credentials (ADC):

```bash
gcloud auth application-default login
```

## 1) Initialize Terraform

```bash
terraform init
```

## 2) Plan and apply

```bash
terraform plan
terraform apply
```

## Notes

- This repository ignores local state files and `.tfvars` files via `.gitignore`.
- Backend settings live in `backend.tf`, so no per-user backend config file is needed.
