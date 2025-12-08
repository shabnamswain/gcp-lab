project_id = "leafy-glyph-477712-p3"
region     = "us-central1"
zone       = "us-central1-a"  
stg_buck_name = "csv-upload-bucket-shab1"
object_name   = "function-source.zip"
fcn_source    = "./function-source.zip"
vpc_name          = "project-vpc"
subnet_fcn_name   = "subnet-function"
fcn_ip_cidr_range = "10.10.0.0/24"
subnet_sql_name   = "subnet-sql"
sql_ip_cidr_range = "10.20.0.0/24"
subnet_vm_name    = "subnet-vm"
vm_ip_cidr_range  = "10.30.0.0/24"

fcn_conn_name           = "function-connector"
fcn_conn_ip_cidr_range  = "10.40.0.0/28"

db_instance_name    = "mysql-emp-db"
database_version    = "MYSQL_8_0"
deletion_protection = false
tier                = "db-f1-micro"

sql_db_name       = "employee_db"
sql_user_name     = "emp_user"
sql_user_password = "ChangeMe-StrongPassword!"

cld_fcn_name = "csv-handler-fn"
runtime      = "python310"
entry_point  = "main"
trigger_http = true

vm_name      = "apache-vm"
machine_type = "e2-micro"
image        = "ubuntu-os-cloud/ubuntu-2204-lts"
