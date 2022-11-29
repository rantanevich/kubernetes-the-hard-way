variable "name_prefix" { default = "k8s" }

variable "google_project" {}
variable "google_region" {}

variable "machine_type" { default = "e2-standard-2" }
variable "subnet_cidr" { default = "10.0.0.0/24" }

variable "master_nodes" { default = 3 }
variable "master_network_ip_template" { default = "10.0.0.1%d" }

variable "worker_nodes" { default = 3 }
variable "worker_network_ip_template" { default = "10.0.0.2%d" }
variable "pods_network_template" { default = "192.168.%d.0/24" }
