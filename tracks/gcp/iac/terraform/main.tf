terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "db_password" {
  type      = string
  default   = "hardcoded-password"
  sensitive = true
}

resource "google_compute_network" "vpc" {
  name                    = "novaledger-gcp-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "novaledger-gcp-subnet"
  ip_cidr_range = "10.70.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_container_cluster" "gke" {
  name     = "novaledger-gke"
  location = var.region

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
  }

  release_channel {
    channel = "RAPID"
  }
}

resource "google_container_node_pool" "default" {
  name       = "default-pool"
  cluster    = google_container_cluster.gke.name
  location   = var.region
  node_count = 1

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_sql_database_instance" "postgres" {
  name             = "novaledger-gcp-postgres"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    backup_configuration {
      enabled = false
    }
    ip_configuration {
      ipv4_enabled                                  = true
      authorized_networks { value = "0.0.0.0/0" }
      require_ssl                                   = false
    }
    disk_encryption_configuration {
      kms_key_name = ""
    }
  }

  deletion_protection = false
}

resource "google_sql_user" "admin" {
  name     = "admin"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}
