locals {
    gcp_services = [
      "workstations.googleapis.com"
    ]
}

resource "google_project_service" "enabled" {
  for_each = toset(local.gcp_services)

  project = var.gcp_project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}
