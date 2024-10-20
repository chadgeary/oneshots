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
  datapath_provider        = "ADVANCED_DATAPATH"
  deletion_protection      = false
  initial_node_count       = 1
  location                 = var.gcp.google_compute_zones.names[0]
  name                     = var.install.name
  network                  = "projects/${var.install.name}/global/networks/${var.install.name}"
  project                  = var.install.name
  remove_default_node_pool = true
  subnetwork               = "projects/${var.install.name}/regions/${var.install.region}/subnetworks/${var.install.name}-private"
  addons_config {
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    gcs_fuse_csi_driver_config {
      enabled = true
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
    machine_type = "e2-standard-2"
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
    ignore_changes = [node_config]
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
    min_node_count = 0
    max_node_count = 2
  }
  node_config {
    disk_size_gb = 10
    disk_type    = "pd-standard"
    machine_type = "t2d-standard-1"
    spot         = true
  }
}