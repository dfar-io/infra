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

variable "workstations_config_id" {
  description = "ID for the Workstations configuration."
  type        = string
  default     = "default-workstations-config"
}

variable "workstations_machine_type" {
  description = "Machine type for workstation hosts."
  type        = string
  default     = "e2-standard-4"
}

variable "workstation_id" {
  description = "ID for the individual workstation instance."
  type        = string
  default     = "default-workstation"
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

resource "google_workstations_workstation_config" "default" {
  provider                = google-beta
  project                 = var.gcp_project_id
  location                = var.gcp_region
  workstation_cluster_id  = google_workstations_workstation_cluster.default.workstation_cluster_id
  workstation_config_id   = var.workstations_config_id

  idle_timeout    = "1200s"
  running_timeout = "43200s"

  host {
    gce_instance {
      machine_type                = var.workstations_machine_type
      boot_disk_size_gb           = 100
      disable_public_ip_addresses = true
    }
  }

  container {
    image = "us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest"
  }

  depends_on = [google_workstations_workstation_cluster.default]
}

resource "google_workstations_workstation" "default" {
  provider                = google-beta
  project                 = var.gcp_project_id
  location                = var.gcp_region
  workstation_cluster_id  = google_workstations_workstation_cluster.default.workstation_cluster_id
  workstation_config_id   = google_workstations_workstation_config.default.workstation_config_id
  workstation_id          = var.workstation_id

  depends_on = [google_workstations_workstation_config.default]
}
