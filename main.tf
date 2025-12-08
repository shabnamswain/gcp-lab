data "google_project" "project" {
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [data.google_project.project]

  create_duration = "30s"
}

# Enable necessary APIs
resource "google_project_service" "api_services" {
  for_each = toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "vpcaccess.googleapis.com",
    "storage.googleapis.com"
  ])
  project = "leafy-glyph-477712-p3"
  service = each.key
  disable_dependent_services = true
  depends_on = [time_sleep.wait_30_seconds]
}

# ------------------------------------------
# Storage Bucket (CSV Upload)
# ------------------------------------------
resource "google_storage_bucket" "csv_bucket" {
  name     = var.stg_buck_name
  location = var.region
  force_destroy = true
}


resource "google_storage_bucket_object" "function_zip" {
  name   = var.object_name
  bucket = google_storage_bucket.csv_bucket.name
  source = var.fcn_source

  depends_on = [
    google_storage_bucket.csv_bucket
  ]
}

# ------------------------------------------
# VPC + Subnets
# ------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_function" {
  name          = var.subnet_fcn_name
  ip_cidr_range = var.fcn_ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "subnet_sql" {
  name          = var.subnet_sql_name
  ip_cidr_range = var.sql_ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "subnet_vm" {
  name          = var.subnet_vm_name
  ip_cidr_range = var.vm_ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc.id
}


# ------------------------------------------
# Serverless VPC Connector
# ------------------------------------------
resource "google_vpc_access_connector" "function_connector" {
  name          = var.fcn_conn_name
  network       = google_compute_network.vpc.name
  region        = var.region
  ip_cidr_range = var.fcn_conn_ip_cidr_range
  min_instances = 2
  max_instances = 3

  depends_on = [
    google_compute_subnetwork.subnet_function
  ]
}


# Reserve an internal range for peering (must NOT overlap your subnets)
resource "google_compute_global_address" "private_ip_range" {
  name          = "cloudsql-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address      = "10.50.0.0"
  prefix_length = 16  

  network       = google_compute_network.vpc.name
}

# Create the peering between your VPC and Google's service network
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]

  # depends_on = [google_project_service.apis]
}


# ------------------------------------------
# Cloud SQL
# ------------------------------------------
resource "google_sql_database_instance" "mysql" {
  name                = var.db_instance_name
  database_version    = var.database_version
  deletion_protection = var.deletion_protection
  region        = var.region

  settings {
    tier = var.tier   
    ip_configuration {
    ipv4_enabled    = false
    private_network = google_compute_network.vpc.id
  }
 }
  depends_on = [
    google_compute_subnetwork.subnet_sql,
    google_compute_network.vpc,
    google_service_networking_connection.private_vpc_connection
  ]
}

resource "google_sql_database" "employee_db" {
  name     = var.sql_db_name
  instance = google_sql_database_instance.mysql.name

  depends_on = [
    google_sql_database_instance.mysql
  ]
}

resource "google_sql_user" "user" {
  name     = var.sql_user_name
  instance = google_sql_database_instance.mysql.name
  password = var.sql_user_password

  depends_on = [
    google_sql_database_instance.mysql
  ]
}

# ------------------------------------------
# Cloud Function
# ------------------------------------------
resource "google_cloudfunctions_function" "csv_handler" {
  name                  = var.cld_fcn_name
  runtime               = var.runtime
  entry_point           = var.entry_point
  source_archive_bucket = google_storage_bucket.csv_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  region        = var.region
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.csv_bucket.name
  }
    available_memory_mb   = 256

  environment_variables = {
    DB_NAME     = google_sql_database.employee_db.name
    DB_USER     = google_sql_user.user.name
    DB_PASSWORD = google_sql_user.user.password
    DB_HOST     = google_sql_database_instance.mysql.private_ip_address
  }

  vpc_connector = google_vpc_access_connector.function_connector.name
  vpc_connector_egress_settings = "ALL_TRAFFIC"

  depends_on = [
    google_storage_bucket_object.function_zip,
    google_vpc_access_connector.function_connector,
    google_sql_database.employee_db,
    google_sql_user.user
  ]
}

# ------------------------------------------
# Firewall Rules
# ------------------------------------------
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["apache-web"]

  depends_on = [
    google_compute_network.vpc
  ]
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["apache-web"]

  depends_on = [
    google_compute_network.vpc
  ]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["apache-web"]

  depends_on = [
    google_compute_network.vpc
  ]
}

resource "google_compute_firewall" "allow_egress" {
  name    = "allow-egress"
  network = google_compute_network.vpc.name

  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]

  depends_on = [
    google_compute_network.vpc
  ]
}

# ------------------------------------------
# VM (Apache)
# ------------------------------------------
resource "google_compute_instance" "vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  tags         = ["apache-web"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_vm.id
    access_config {}
  }

#   metadata_startup_script = <<-EOF
# #!/bin/bash
# set -e
# apt-get update -y
# apt-get install -y apache2
# systemctl enable apache2
# systemctl restart apache2
# echo "<h1>Apache Running</h1>" > /var/www/html/index.html
# EOF


  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2 mysql-client python3-pip
    pip3 install flask pymysql
    cat << 'EOL' > /var/www/html/index.html
    <html><body><h2>Employee Database Query</h2>
    <pre>
    $(mysql -h ${google_sql_database_instance.mysql.private_ip_address} \
            -u ${google_sql_user.user.name} \
            -p${google_sql_user.user.password} \
            -D employee_db -e "SELECT * FROM employees;")
    </pre>
    </body></html>
    EOL
    sudo systemctl restart apache2
  EOF


  depends_on = [
    google_compute_subnetwork.subnet_vm,
    google_compute_firewall.allow_http,
    google_compute_firewall.allow_https,
    google_compute_firewall.allow_ssh
  ]
}
