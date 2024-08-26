# oneshots/example/k3s

A budget-friendly k3s cluster in aws with a single `terraform apply`:

- ~$8/month
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

- arm instances are used where available, empty [../../modules/k3s/data-ec2.tf#L4](../../modules/k3s/data-ec2.tf#L4) to force amd64
- nodes have 5Gi of storage, see [../../modules/k3s/main-worker.tf#L59](../../modules/k3s/main-worker.tf#L59)
- certificate + dns name(s) are `*.{var.install.name}.duckdns.org`
- after apply, local file `config` can be used as `KUBECONFIG=config kubectl get nodes`
