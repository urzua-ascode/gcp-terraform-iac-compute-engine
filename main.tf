terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.network_name}-public"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.network_name}-private"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

data "google_compute_image" "debian" {
  family  = "debian-11"
  project = "debian-cloud"
}

locals {
  web_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx

    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install
  EOT

  db_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y postgresql postgresql-contrib

    sudo -u postgres psql -c "CREATE USER appuser WITH PASSWORD 'changeme';"
    sudo -u postgres psql -c "CREATE DATABASE appdb OWNER appuser;"

    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf
    echo "host all all 10.10.1.0/24 md5" >> /etc/postgresql/*/main/pg_hba.conf
    systemctl restart postgresql

    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install
  EOT
}

resource "google_compute_instance" "web_vm" {
  name         = var.public_vm_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = var.tags_web

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
  }

  metadata_startup_script = local.web_startup_script
}

resource "google_compute_instance" "db_vm" {
  name         = var.private_vm_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = var.tags_db

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
  }

  metadata_startup_script = local.db_startup_script
}

resource "google_compute_firewall" "http_ingress" {
  name    = "allow-http-to-web"
  network = google_compute_network.vpc.name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = var.tags_web
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc.name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = concat(var.tags_web, var.tags_db)
  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "db_ingress" {
  name    = "allow-postgres-internal"
  network = google_compute_network.vpc.name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  target_tags   = var.tags_db
  source_ranges = [var.public_subnet_cidr, var.private_subnet_cidr]
}
