resource "google_compute_network" "vpc_gke" {
  name = "project-vpc-gke"
}

resource "google_compute_subnetwork" "subnet_gke" {
  name          = "project-subn-gke"
  ip_cidr_range = "10.2.0.0/16"
  network       = google_compute_network.vpc_gke.name
}

resource "google_container_cluster" "gke_cluster" {
  name     = "my-gke-cluster"
  location = "us-central1"
  enable_autopilot = true
  network  = google_compute_network.vpc_gke.name
  subnetwork = google_compute_subnetwork.subnet_gke.name
  initial_node_count       = 1
  deletion_protection = false
}

# resource "google_container_node_pool" "primary_preemptible_nodes" {
#   cluster    = google_container_cluster.gke_cluster.name
#   node_count = 3
#   node_config {
#     disk_type    = "pd-standard"
#     disk_size_gb = 50
#     machine_type = "e2-medium"
#     preemptible  = true
 
#   }
# }


