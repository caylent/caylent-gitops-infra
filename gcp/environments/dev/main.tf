provider "google" {
  project = var.project
}

resource "google_compute_network" "vpc" {
  name = "${var.company}-${var.env}-vpc"
  auto_create_subnetworks = "false"
  routing_mode = "GLOBAL"
}

resource "google_compute_subnetwork" "private_subnet" {
  name = "${var.project}-${var.env}-private-subnet"
  ip_cidr_range = var.private_subnet
  network = google_compute_network.vpc.self_link
  region = var.region_name
}

resource "google_container_cluster" "primary" {
  name = "${var.project}-${var.env}-gke"
  location = var.region_name

  remove_default_node_pool = false
  initial_node_count = var.gke_num_nodes

  network = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.private_subnet.name

  master_auth {
    username = var.gke_username
    password = var.gke_password

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]

    labels = {
      env = "${var.project}-${var.env}"
    }

    machine_type = "n1-standard-1"
    tags = [
      "gke-node",
      "${var.project}-${var.env}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_compute_firewall" "allow-internal" {
  name = "${var.company}-${var.env}-fw-allow-internal"
  network = google_compute_network.vpc.name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports = [
      "0-65535"]
  }
  allow {
    protocol = "udp"
    ports = [
      "0-65535"]
  }
  source_ranges = [
    var.private_subnet
  ]
}

resource "google_compute_firewall" "allow-http" {
  name = "${var.company}-${var.env}-fw-allow-http"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports = [
      "80"]
  }
  target_tags = [
    "http"]
}

resource "google_compute_firewall" "allow-bastion" {
  name = "${var.company}-${var.env}-fw-allow-bastion"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports = [
      "22"]
  }
  target_tags = [
    "ssh"]
}