resource "google_compute_firewall" "this" {
  name               = "${var.install.name}-gke"
  direction          = "EGRESS"
  network            = "projects/${var.install.name}/global/networks/${var.install.name}"
  priority           = "100"
  project            = var.install.name
  destination_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "all"
  }
}

resource "google_container_cluster" "this" {
  deletion_protection      = false
  initial_node_count       = 1
  location                 = var.gcp.google_compute_zones.names[0]
  name                     = var.install.name
  network                  = "projects/${var.install.name}/global/networks/${var.install.name}"
  project                  = var.install.name
  remove_default_node_pool = true
  subnetwork               = "projects/${var.install.name}/regions/${var.install.region}/subnetworks/${var.install.name}-private"
  addons_config {
    http_load_balancing {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = true
    }
  }
  cluster_autoscaling {
    enabled = false
  }
  logging_config {
    enable_components = []
  }
  maintenance_policy {
    daily_maintenance_window {
      start_time = "06:00"
    }
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "0.0.0.0/0"
    }
  }
  monitoring_config {
    enable_components = []
    managed_prometheus {
      enabled = false
    }
  }
  network_policy {
    enabled = false
  }
  node_config {
    disk_size_gb = 10
    disk_type    = "pd-standard"
    machine_type = "e2-micro"
    tags         = ["${var.install.name}-gke"]
    labels = {
      mesh_id = "proj-${var.install.name}"
    }
  }
  private_cluster_config {
    enable_private_nodes   = true
    master_ipv4_cidr_block = cidrsubnet(cidrsubnet(var.install.network.cidr, 2, 2), 28 - split("/", cidrsubnet(var.install.network.cidr, 2, 2))[1], 1)
  }
  release_channel {
    channel = "REGULAR"
  }
  workload_identity_config {
    workload_pool = "${var.install.name}.svc.id.goog"
  }
  lifecycle {
    ignore_changes = [node_config, node_pool]
  }
  depends_on = [google_compute_firewall.this]
}

resource "google_container_node_pool" "this" {
  name               = var.install.name
  cluster            = google_container_cluster.this.id
  location           = var.gcp.google_compute_zones.names[0]
  initial_node_count = 1
  project            = var.install.name
  node_locations     = [var.gcp.google_compute_zones.names[0]]
  autoscaling {
    min_node_count = var.install.gke.min_node_count
    max_node_count = var.install.gke.max_node_count
  }
  node_config {
    disk_size_gb = var.install.gke.disk_size_gb
    disk_type    = "pd-standard"
    machine_type = var.install.gke.machine_type
    spot         = true
    tags         = ["${var.install.name}-gke"]
  }
  lifecycle {
    ignore_changes = [initial_node_count]
  }
}