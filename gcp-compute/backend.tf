terraform {
  backend "gcs" {
    bucket = "resourcestatefile"
    prefix = "uat/compute"
  }
}
