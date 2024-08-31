# oneshots/example/k3s

A budget-friendly k3s cluster in aws with a single `terraform apply`:

- ~$15/month
- self-healing nodes
- duckdns.org domain with letsencrypt wildcard certificate
- support for AWS IRSA
- autoscaling workers
- secure istio ingress gateway and mTLS mesh

## requirements

- access to aws - validate w/ `aws sts get-caller-identity`
- name and duckdnstoken
  - visit duckdns.org to generate register a name and token
  - add to [./variables.tf](./variables.tf)

## notes

- default instance types are arm64
- certificate + dns name(s) are `*.{var.install.name}.duckdns.org`
- after apply, local file `config` can be used as `KUBECONFIG=./config kubectl get nodes`
