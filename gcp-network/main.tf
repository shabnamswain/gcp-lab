#################################
# PROJECT + API ENABLEMENT
#################################

data "google_project" "project" {}

resource "google_project_service" "api_services" {
  for_each = toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "vpcaccess.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com"
  ])

  project = data.google_project.project.project_id
  service = each.key
  disable_dependent_services = true
}


# ########################
# # STORAGE (FUNCTION ZIP + CSV)
# ########################

# resource "google_storage_bucket" "csv_bucket" {
#   name     = var.stg_buck_name
#   location = var.region
 
#   lifecycle {
#     prevent_destroy = false
#   }

# }

# resource "google_storage_bucket_object" "function_zip" {
#   name   = var.object_name
#   bucket = google_storage_bucket.csv_bucket.name
#   source = var.fcn_source
# }


# ##################
# # NETWORK / VPC
# ##################

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# resource "google_compute_subnetwork" "subnet_function" {
#   name          = var.subnet_fcn_name
#   ip_cidr_range = var.fcn_ip_cidr_range
#   region        = var.region
#   network       = google_compute_network.vpc.id
#   private_ip_google_access = true
# }

# resource "google_compute_subnetwork" "subnet_sql" {
#   name          = var.subnet_sql_name
#   ip_cidr_range = var.sql_ip_cidr_range
#   region        = var.region
#   network       = google_compute_network.vpc.id
#   private_ip_google_access = true
# }

resource "google_compute_subnetwork" "subnet_vm" {
  name          = var.subnet_vm_name
  ip_cidr_range = var.vm_ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc.id
}

# resource "google_compute_subnetwork" "subnet_vpc_connector" {
#   name          = "vpc-connector-subnet"
#   region        = var.region
#   network       = google_compute_network.vpc.id
#   ip_cidr_range = "10.60.0.0/28"

#   private_ip_google_access = true
# }


# resource "google_vpc_access_connector" "function_connector" {
#   name    = var.fcn_conn_name
#   region  = var.region

#   subnet {
#     name = google_compute_subnetwork.subnet_vpc_connector.name
#   }

#   min_instances = 2
#   max_instances = 3
# }



# ##########################################
# # PRIVATE SERVICE CONNECT (SQL → VPC)
# ##########################################

# resource "google_compute_global_address" "private_ip_range" {
#   name          = "cloudsql-private-ip-range"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   address       = "10.50.0.0"
#   prefix_length = 16
#   network       = google_compute_network.vpc.name
# }

# resource "google_service_networking_connection" "private_vpc_connection" {
#   network                 = google_compute_network.vpc.id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
# }


# ########################
# # CLOUD SQL INSTANCE
# ########################

# resource "google_sql_database_instance" "mysql" {
#   name             = var.db_instance_name
#   region           = var.region
#   database_version = var.database_version
#   deletion_protection = false

#   settings {
#     tier = var.tier

#     ip_configuration {
#       ipv4_enabled                             = false
#       private_network                           = google_compute_network.vpc.id
#       enable_private_path_for_google_cloud_services = true
#     }
#   }

#   depends_on = [
#     google_compute_subnetwork.subnet_sql,
#     google_service_networking_connection.private_vpc_connection
#   ]
# }

# resource "google_sql_database" "employee_db" {
#   name     = var.sql_db_name
#   instance = google_sql_database_instance.mysql.name
# }

# resource "google_sql_user" "user" {
#   name     = var.sql_user_name
#   instance = google_sql_database_instance.mysql.name
#   password = var.sql_user_password
# }


# ###########################
# # PUB/SUB — GCS NOTIFICATIONS
# ###########################

# resource "google_pubsub_topic" "gcs_events" {
#   name = "gcs-events-topic"
# }

# resource "google_pubsub_topic_iam_binding" "gcs_publish_permission" {
#   topic = google_pubsub_topic.gcs_events.name
#   role  = "roles/pubsub.publisher"

#   members = [
#     "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
#   ]
# }

# resource "google_storage_notification" "bucket_notifications" {
#   bucket         = google_storage_bucket.csv_bucket.name
#   topic          = google_pubsub_topic.gcs_events.id
#   event_types    = ["OBJECT_FINALIZE"]
#   payload_format = "JSON_API_V1"   # Provides attributes.bucketId / attributes.objectId

#   depends_on = [
#     google_pubsub_topic_iam_binding.gcs_publish_permission
#   ]
# }

# resource "google_service_account" "pubsub_invoker" {
#   account_id   = "pubsub-invoker"
#   display_name = "Pub/Sub Invoker SA"
# }


# #############################
# # CLOUD FUNCTION 2ND GEN
# #############################

# resource "google_cloudfunctions2_function" "csv_handler" {
#   name     = var.cld_fcn_name
#   location = var.region

#   build_config {
#     runtime     = var.runtime
#     entry_point = var.entry_point

#     source {
#       storage_source {
#         bucket = google_storage_bucket.csv_bucket.name
#         object = google_storage_bucket_object.function_zip.name
#       }
#     }
#   }

#   service_config {
#     max_instance_count = 3
#     # min_instance_count = 1
#     ingress_settings   = "ALLOW_ALL"
#     timeout_seconds = 60

#     environment_variables = {
#       DB_NAME      = google_sql_database.employee_db.name
#       DB_USER      = google_sql_user.user.name
#       DB_PASSWORD  = google_sql_user.user.password
#       DB_HOST      = google_sql_database_instance.mysql.private_ip_address
#       PUBSUB_TOPIC = google_pubsub_topic.gcs_events.name
#     }

#     vpc_connector = google_vpc_access_connector.function_connector.name
#     vpc_connector_egress_settings = "ALL_TRAFFIC"
#   }
# }


# ###################################################
# # IAM FOR PUB/Sub → CLOUD FUNCTION PUSH CALLS
# ###################################################

# resource "google_cloud_run_service_iam_member" "allow_pubsub_invoker" {
#   location = var.region
#   service  = google_cloudfunctions2_function.csv_handler.name
#   role     = "roles/run.invoker"
#   member   = "serviceAccount:${google_service_account.pubsub_invoker.email}"
# }

# resource "google_cloud_run_service_iam_member" "allow_pubsub_service" {
#   location = var.region
#   service  = google_cloudfunctions2_function.csv_handler.name
#   role     = "roles/run.invoker"
#   member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
# }

# resource "google_cloud_run_service_iam_member" "allow_all_invoker" {
#   location = var.region
#   service  = google_cloudfunctions2_function.csv_handler.name
#   role     = "roles/run.invoker"
#   member   = "allUsers"
# }

# ###################################################
# # PUB/Sub → FUNCTION (PUSH SUBSCRIPTION)
# ###################################################

# resource "google_pubsub_subscription" "gcs_push_to_function" {
#   name  = "gcs-events-push-sub"
#   topic = google_pubsub_topic.gcs_events.name

#   push_config {
#     push_endpoint = google_cloudfunctions2_function.csv_handler.service_config[0].uri

#     oidc_token {
#       service_account_email = google_service_account.pubsub_invoker.email
#     }
#   }

#   depends_on = [
#     google_cloud_run_service_iam_member.allow_pubsub_invoker,
#     google_cloud_run_service_iam_member.allow_pubsub_service,
#     google_cloud_run_service_iam_member.allow_all_invoker
#   ]
# }



# #################################
# # FIREWALL RULES
# #################################

# # resource "google_compute_firewall" "allow_mysql_internal" {
# #   name    = "allow-mysql-internal"
# #   network = google_compute_network.vpc.name

# #   direction = "INGRESS"

# #   allow {
# #     protocol = "tcp"
# #     ports    = ["3306"]
# #   }

# #   source_ranges = [
# #     "10.60.0.0/28",
# #     var.vm_ip_cidr_range
# #   ]
# # }



# resource "google_compute_firewall" "allow_http" {
#   name    = "allow-http"
#   network = google_compute_network.vpc.name

#   allow {
#     protocol = "tcp"
#     ports    = ["80"]
#   }

#   direction     = "INGRESS"
#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["apache-web"]
# }


# resource "google_compute_firewall" "allow_https" {
#   name    = "allow-https"
#   network = google_compute_network.vpc.name

#   allow {
#     protocol = "tcp"
#     ports    = ["443"]
#   }

#   direction     = "INGRESS"
#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["apache-web"]
# }


# resource "google_compute_firewall" "allow_ssh" {
#   name    = "allow-ssh"
#   network = google_compute_network.vpc.name

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   direction     = "INGRESS"
#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["apache-web"]
# }


# resource "google_compute_firewall" "allow_egress" {
#   name      = "allow-egress"
#   network   = google_compute_network.vpc.name
#   direction = "EGRESS"

#   allow {
#     protocol = "all"
#   }

#   destination_ranges = ["0.0.0.0/0"]
# }



###########################
# VM WITH APACHE + PHP
###########################

# resource "google_compute_instance" "vm" {
#   name         = var.vm_name
#   machine_type = var.machine_type
#   tags         = ["apache-web"]

#   boot_disk {
#     initialize_params { image = var.image }
#   }

#   network_interface {
#     subnetwork   = google_compute_subnetwork.subnet_vm.id
#     access_config {}
#   }

#   metadata_startup_script = <<-EOF
# #!/bin/bash
# sudo apt-get update
# sudo apt-get install -y apache2 php libapache2-mod-php php-mysql mysql-client
# sudo systemctl restart apache2
# EOF
# }

# cat << 'EOL' > /var/www/html/index.php
# <?php
# $host = "${google_sql_database_instance.mysql.private_ip_address}";
# $user = "${google_sql_user.user.name}";
# $pass = "${google_sql_user.user.password}";
# $db = "employee_db";

# $conn = new mysqli($host, $user, $pass, $db);
# if ($conn->connect_error) {
#     die("Connection failed: " . $conn->connect_error);
# }

# $result = $conn->query("SELECT * FROM employees");
# echo "<h2>Employee Database Query</h2>";
# echo "<table border='1'>";
# echo "<tr><th>ID</th><th>Name</th><th>Role</th><th>Department</th></tr>";

# while ($row = $result->fetch_assoc()) {
#     echo "<tr>";
#     echo "<td>{$row['id']}</td><td>{$row['name']}</td>";
#     echo "<td>{$row['role']}</td><td>{$row['department']}</td>";
#     echo "</tr>";
# }
# echo "</table>";
# $conn->close();
# ?>
# EOL
# EOF