resource "google_compute_network" "this" {
  name                    = var.install.name
  auto_create_subnetworks = "false"
  project                 = var.install.name
}

resource "google_compute_subnetwork" "this-public" {
  name                     = "${var.install.name}-public"
  ip_cidr_range            = cidrsubnet(var.install.network.cidr, 2, 0)
  network                  = google_compute_network.this.id
  private_ip_google_access = "true"
  project                  = var.install.name
}

resource "google_compute_subnetwork" "this-private" {
  name                     = "${var.install.name}-private"
  ip_cidr_range            = cidrsubnet(var.install.network.cidr, 2, 1)
  network                  = google_compute_network.this.id
  private_ip_google_access = "true"
  project                  = var.install.name
}

resource "google_service_account" "this" {
  account_id   = "${var.install.name}-nat"
  display_name = "${var.install.name}-nat"
  project      = var.install.name
}

resource "google_compute_address" "this" {
  name         = "${var.install.name}-nat"
  address_type = "EXTERNAL"
  network_tier = "STANDARD"
  project      = var.install.name
  region       = var.install.region
}

resource "google_compute_instance_template" "this" {
  name_prefix    = "${var.install.name}-nat"
  can_ip_forward = true
  machine_type   = "e2-micro"
  project        = var.install.name
  tags           = ["${var.install.name}-nat"]

  disk {
    source_image = var.gcp.google_compute_image.debian.id
  }

  metadata = {
    startup-script = <<EOF
#!/bin/bash -x

# forwarding
sysctl -q -w net.ipv4.ip_forward=1

# reverse path
for i in $(find /proc/sys/net/ipv4/conf/ -name rp_filter) ; do
  echo 0 > $i;
done

# NAT
ENI_IFACE=$(ip route | grep default | awk '{print $5}')
iptables -t nat -F
iptables -t nat -A POSTROUTING -o "$ENI_IFACE" -j MASQUERADE -m comment --comment "NAT Gateway"

# ACCEPT
iptables -t nat -A PREROUTING -s ${cidrsubnet(var.install.network.cidr, 2, 1)} -j ACCEPT

cat > /opt/forward.sh << 'EOM'
while true
do
  sleep 15
  TARGET_NODE=$(gcloud compute instances list \
    --filter="tags.items=${var.install.name}-gke" \
    --format="value(networkInterfaces[0].networkIP)" \
    --sort-by="networkInterfaces[0].networkIP" \
    --limit=1)
  echo $TARGET_NODE > /opt/TARGET_NODE
  if iptables -t nat -L PREROUTING --line-numbers | grep DNAT | grep --quiet $TARGET_NODE
  then
    echo "nothing to do."
  else
    iptables -t nat -D PREROUTING 3
    iptables -t nat -D PREROUTING 2
    declare -a PORT_FORWARDS=("80:31080" "443:31443")
    for PORT_FORWARD in "$${PORT_FORWARDS[@]}"
    do
      SRC_PORT=$(echo "$PORT_FORWARD" | awk -F':' '{print $1}' )
      DST_PORT=$(echo "$PORT_FORWARD" | awk -F':' '{print $2}' )
      iptables -t nat -A PREROUTING -p tcp --dport $SRC_PORT -j DNAT --to-destination $TARGET_NODE:$DST_PORT
    done
  fi
done
EOM
chmod +x /opt/forward.sh
/opt/forward.sh &

EOF
  }

  network_interface {
    network_ip = cidrhost(cidrsubnet(var.install.network.cidr, 2, 0), 10)
    stack_type = "IPV4_ONLY"
    subnetwork = google_compute_subnetwork.this-public.id
    access_config {
      nat_ip       = google_compute_address.this.address
      network_tier = "STANDARD"
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [disk]
  }
}

resource "google_compute_target_pool" "this" {
  name    = "${var.install.name}-nat"
  project = var.install.name
}

resource "google_compute_instance_group_manager" "this" {
  name               = "${var.install.name}-nat"
  base_instance_name = "${var.install.name}-nat"
  project            = var.install.name
  target_pools       = [google_compute_target_pool.this.id]
  zone               = var.gcp.google_compute_zones.names[0]
  instance_lifecycle_policy {
    force_update_on_repair = "YES"
  }
  version {
    instance_template = google_compute_instance_template.this.id
  }
}

resource "google_compute_autoscaler" "this" {
  name    = "${var.install.name}-nat"
  project = var.install.name
  target  = google_compute_instance_group_manager.this.id
  zone    = var.gcp.google_compute_zones.names[0]
  autoscaling_policy {
    max_replicas    = 1
    min_replicas    = 1
    cooldown_period = 60
  }
}

resource "google_compute_route" "this" {
  name                   = "${var.install.name}-nat"
  dest_range             = "0.0.0.0/0"
  network                = google_compute_network.this.id
  next_hop_instance_zone = var.gcp.google_compute_zones.names[0]
  next_hop_ip            = cidrhost(cidrsubnet(var.install.network.cidr, 1, 0), 10)
  priority               = 500
  project                = var.install.name
  tags                   = ["${var.install.name}-gke"]
  depends_on             = [google_compute_subnetwork.this-public]
}

resource "google_compute_firewall" "this-nat" {
  name        = "${var.install.name}-nat"
  network     = google_compute_network.this.id
  priority    = "500"
  project     = var.install.name
  target_tags = ["${var.install.name}-nat"]
  source_tags = ["${var.install.name}-gke"]
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "this-iap" {
  name          = "${var.install.name}-nat-ssh"
  network       = google_compute_network.this.id
  priority      = "500"
  project       = var.install.name
  source_ranges = ["35.235.240.0/20"] # https://cloud.google.com/iap/docs/using-tcp-forwarding
  target_tags   = ["${var.install.name}-gke", "${var.install.name}-nat"]
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "this-gateway-nat" {
  name          = "${var.install.name}-gateway-nat"
  network       = google_compute_network.this.id
  priority      = "500"
  project       = var.install.name
  target_tags   = ["${var.install.name}-nat"]
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "this-gateway-gke" {
  name        = "${var.install.name}-gateway-gke"
  network     = google_compute_network.this.id
  priority    = "500"
  project     = var.install.name
  target_tags = ["${var.install.name}-gke"]
  source_tags = ["${var.install.name}-nat"]
  allow {
    protocol = "tcp"
    ports    = ["31080", "31443"]
  }
}