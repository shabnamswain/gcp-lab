terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.12.0"
    }
  }
}

provider "google" {
  project = "leafy-glyph-477712-p3"
  region  = "us-central1"
}

