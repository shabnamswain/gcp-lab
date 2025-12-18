terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.12.0"
    }
  }
}

# terraform {
#     backend "gcs" { 
#       bucket  = "terraformstatecicdbucket"
#       prefix  = "prd"
#     }
# }

provider "google" {
  project = "leafy-glyph-477712-p3"
  region  = "us-central1"
  zone    = "us-central1-a"
}


#workflow dispatch
# SA
# WIF
# LINK SA
