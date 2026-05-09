terraform {
  backend "gcs" {
    # needs to be created manually first
    bucket = "dfar-terraform-state"
    prefix = "infra/state"
  }
}
