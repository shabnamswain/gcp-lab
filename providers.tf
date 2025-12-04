terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.12.0"
    }
  }
}

terraform {
    backend "gcs" { 
      bucket  = "terraformstatecicdbucket"
      prefix  = "vang"
    }
}

provider "google" {
  project = "leafy-glyph-477712-p3"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_project_service" "api_services" {
  for_each = toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "storage.googleapis.com"
  ])
  project = "leafy-glyph-477712-p3"
  service = each.key
}


#workflow dispatch
# SA
# WIF
# LINK SA
