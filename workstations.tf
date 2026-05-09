variable "workstations_cluster_id" {
  description = "ID for the Workstations cluster."
  type        = string
  default     = "default-workstations-cluster"
}

variable "workstations_network_name" {
  description = "VPC network name used by the Workstations cluster."
  type        = string
  default     = "default"
}

variable "workstations_subnetwork_name" {
  description = "Subnetwork name used by the Workstations cluster."
  type        = string
  default     = "default"
}

data "google_compute_network" "workstations" {
  name = var.workstations_network_name
}

data "google_compute_subnetwork" "workstations" {
  name   = var.workstations_subnetwork_name
  region = var.gcp_region
}

resource "google_workstations_workstation_cluster" "default" {
  provider               = google-beta
  project                = var.gcp_project_id
  location               = var.gcp_region
  workstation_cluster_id = var.workstations_cluster_id

  network    = data.google_compute_network.workstations.id
  subnetwork = data.google_compute_subnetwork.workstations.id

  labels = {
    managed-by = "terraform"
  }

  depends_on = [google_project_service.enabled]
}
