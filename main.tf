# Enable necessary APIs
resource "google_project_service" "api_services" {
  for_each = toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
    # "cloudsql.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "storage.googleapis.com"
  ])
  project = "leafy-glyph-477712-p3"
  service = each.key
}

resource "google_compute_network" "vpc_lab" {
  name = "project-vpc"
}

resource "google_compute_subnetwork" "subnet_lab" {
  name          = "project-subn"
  ip_cidr_range = "10.2.0.0/16"
  network       = google_compute_network.vpc_lab.id
}

resource "google_compute_firewall" "lab_firewall" {
  name    = "project-firewall"
  network = google_compute_network.vpc_lab.name

  #   allow {
  #     protocol = "icmp"
  #   }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "443", "22", "1000-2000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["apply-to-all"]

}


resource "google_service_account" "default" {
  account_id   = "my-custom-sa"
  display_name = "Custom SA for VM Instance"
}

resource "google_compute_instance" "default" {
  name         = "my-vm-instance-01"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  tags = ["apply-to-all"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    network = "project-vpc"

    access_config {
      // Ephemeral public IP
    }
  }
  metadata_startup_script = <<-EOT
  #!/bin/bash
  set -xe
  apt-get update
  apt-get install -y apache2
  echo "Hello World from $(hostname) $(hostname -i)" > /var/www/html/index.html
  systemctl enable apache2
  systemctl restart apache2
EOT


  service_account {
    email  = google_service_account.project_sa.email
    scopes = ["cloud-platform"]
  }
}

resource "google_service_account" "project_sa" {
  account_id   = "project-vm-sa"
  display_name = "project VM Service Account"
}

resource "google_storage_bucket" "project_stb" {
  name          = "image-store-shab"
  location      = "us-central1"
#   force_destroy = true

#   uniform_bucket_level_access = true

#   website {
#     main_page_suffix = "index.html"
#     not_found_page   = "404.html"
#   }
#   cors {
#     origin          = ["http://image-store.com"]
#     method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
#     response_header = ["*"]
#     max_age_seconds = 3600
#   }
#   cors {
#     origin            = ["http://image-store.com"]
#     method            = ["GET", "HEAD", "PUT", "POST", "DELETE"]
#     response_header   = ["*"]
#     max_age_seconds   = 0
#   }
}