output "this" {
  value = {
    cluster = google_container_cluster.this
    files = {
      config = <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${google_container_cluster.this.master_auth[0].cluster_ca_certificate}
    server: https://${google_container_cluster.this.endpoint}
  name: gke_${var.install.name}_${var.gcp.google_compute_zones.names[0]}_${var.install.name}
contexts:
- context:
    cluster: gke_${var.install.name}_${var.gcp.google_compute_zones.names[0]}_${var.install.name}
    user: gke_${var.install.name}_${var.gcp.google_compute_zones.names[0]}_${var.install.name}
  name: gke_${var.install.name}_${var.gcp.google_compute_zones.names[0]}_${var.install.name}
current-context: gke_${var.install.name}_${var.gcp.google_compute_zones.names[0]}_${var.install.name}
kind: Config
preferences: {}
users:
- name: gke_${var.install.name}_${var.gcp.google_compute_zones.names[0]}_${var.install.name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: gke-gcloud-auth-plugin
      env:
        - name: CLOUDSDK_CORE_PROJECT
          value: ${var.install.name}
      installHint: Install gke-gcloud-auth-plugin for use with kubectl by following
        https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin
      provideClusterInfo: true
EOF
    }
  }
}
