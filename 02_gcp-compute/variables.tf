
# Project & Region
variable "project_id" {
  type        = string
  description = "GCP Project ID where resources will be created"
}

variable "region" {
  type        = string
  description = "Default region for regional resources"
  default     = "us-central1"
}

# variable "zone" {
#   type        = string
#   description = "Default zone for zonal resources (e.g., VM)"
#   default     = "us-central1-a"
# }

# # Storage Bucket (CSV Upload)
# variable "stg_buck_name" {
#   type        = string
#   description = "Name of the GCS bucket used to upload CSV/function zip"
# }

# variable "object_name" {
#   type        = string
#   description = "Object name to be created in the bucket (e.g., function.zip)"
# }

# variable "fcn_source" {
#   type        = string
#   description = "Local path to the function source archive (zip)"
# }

# # VPC + Subnets
# variable "vpc_name" {
#   type        = string
#   description = "Name of the VPC network"
# }

# variable "subnet_fcn_name" {
#   type        = string
#   description = "Subnetwork name used by Cloud Function (via VPC connector)"
# }

# variable "fcn_ip_cidr_range" {
#   type        = string
#   description = "CIDR range for the Cloud Function subnetwork"
# }

# variable "subnet_sql_name" {
#   type        = string
#   description = "Subnetwork name used by Cloud SQL"
# }

# variable "sql_ip_cidr_range" {
#   type        = string
#   description = "CIDR range for the Cloud SQL subnetwork"
# }

variable "subnet_vm_name" {
  type        = string
  description = "Subnetwork name used by the VM"
}

variable "vm_ip_cidr_range" {
  type        = string
  description = "CIDR range for the VM subnetwork"
}

# # Serverless VPC Connector
# variable "fcn_conn_name" {
#   type        = string
#   description = "Name of the Serverless VPC Access connector for Cloud Functions"
# }

# variable "fcn_conn_ip_cidr_range" {
#   type        = string
#   description = "CIDR range for the VPC Access connector (must be /28–/24 and non-overlapping)"
# }

# # Cloud SQL
# variable "db_instance_name" {
#   type        = string
#   description = "Cloud SQL instance name"
# }

# variable "database_version" {
#   type        = string
#   description = "Cloud SQL database version (e.g., MYSQL_8_0, POSTGRES_14)"
#   default     = "MYSQL_8_0"
# }

# variable "deletion_protection" {
#   type        = bool
#   description = "Whether to enable deletion protection for Cloud SQL instance"
#   default     = false
# }

# variable "tier" {
#   type        = string
#   description = "Machine tier for Cloud SQL (e.g., db-f1-micro, db-g1-small, db-custom-1-3840)"
#   default     = "db-f1-micro"
# }

# variable "sql_db_name" {
#   type        = string
#   description = "Database name to create inside the Cloud SQL instance"
# }

# variable "sql_user_name" {
#   type        = string
#   description = "SQL username"
# }

# variable "sql_user_password" {
#   type        = string
#   description = "SQL user password"
#   sensitive   = true
# }

# # Cloud Function
# variable "cld_fcn_name" {
#   type        = string
#   description = "Cloud Function name"
# }

# variable "runtime" {
#   type        = string
#   description = "Cloud Function runtime (e.g., python310, nodejs20, go121)"
#   default     = "python310"
# }

# variable "entry_point" {
#   type        = string
#   description = "Entry point (handler) function name in your code"
# }

# variable "trigger_http" {
#   type        = bool
#   description = "Whether the function is triggered via HTTP"
#   default     = true
# }


# VM (Apache)
variable "vm_name" {
  type        = string
  description = "Compute Engine VM name"
}

variable "machine_type" {
  type        = string
  description = "Compute Engine machine type (e.g., e2-micro, e2-standard-2)"
  default     = "e2-micro"
}

variable "image" {
  type        = string
  description = "Boot disk image (e.g., ubuntu-os-cloud/ubuntu-2204-lts)"
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}
