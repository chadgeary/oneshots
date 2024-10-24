# oneshots/example/k3s-on-aws

A budget-friendly k3s cluster in aws with a single `terraform apply`:

- < $20/month with free tier resources and spot nodes
- TLS w/ istio, duckdns, and letsencrypt

## requirements

- access to aws - validate w/ `aws sts get-caller-identity`
- name and duckdnstoken
  - visit duckdns.org to generate register a name and token
  - add to [./variables.tf](./variables.tf)

## notes

- default instance types are arm64
- certificate + dns name(s) are `*.{var.install.name}.duckdns.org`
- after apply, local file `config` can be used as `KUBECONFIG=./config kubectl get nodes`
