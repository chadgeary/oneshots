# oneshots/example/gke

A budget-friendly k8s cluster using Google Cloud's GKE free tier with a single `terraform apply`:

- < $10/month with free tier resources and spot nodes
- TLS w/ istio, duckdns, and letsencrypt

## requires

- [gke-gcloud-auth-plugin](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin)
- name and duckdnstoken
  - visit duckdns.org to generate register a name and token
  - add to [./variables.tf](./variables.tf)
