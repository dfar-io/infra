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

  tags = ["maprodj", "ssh", "http-server", "https-server"]

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    MARKER_FILE="/var/lib/maprodj-startup.done"
    if [[ -f "$MARKER_FILE" ]]; then
      systemctl start nginx || true
      exit 0
    fi

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y ca-certificates curl lsb-release gnupg2 zip nginx mariadb-server

    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list

    apt-get update
    apt-get install -y php7.4-fpm php7.4-mysql php7.4-cli php7.4-curl php7.4-gd php7.4-mbstring php7.4-xml php7.4-zip

    systemctl enable --now nginx
    systemctl enable --now mariadb
    systemctl enable --now php7.4-fpm

    touch "$MARKER_FILE"
  EOT

  labels = {
    managed_by = "terraform"
    vm_name    = "maprodj"
  }

  allow_stopping_for_update = true
}
