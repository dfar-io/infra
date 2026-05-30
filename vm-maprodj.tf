resource "google_compute_instance" "maprodj" {
  name         = "maprodj"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  tags = ["maprodj", "ssh"]

  metadata = {
    enable-oslogin = "TRUE"
  }

  labels = {
    managed_by = "terraform"
    vm_name    = "maprodj"
  }

  allow_stopping_for_update = true
}

resource "google_compute_firewall" "maprodj_allow_http_https" {
  name    = "maprodj-allow-http-https"
  network = "default"

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["maprodj"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}
