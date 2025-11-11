# oneshots/example/gke-on-gcp

A budget-friendly k8s cluster using Google Cloud's GKE free tier with a single `terraform apply`:

- < $10/month with free tier resources and spot nodes
- TLS w/ istio and letsencrypt
- DNS w/ duckdns or cloudflare

## requires

- [gke-gcloud-auth-plugin](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin)
- a domain and token from duckdns.org (free) or cloudflare
- set in a file called `terraform.tfvars`:
  - duckdns, web address will appear like "grafana.chad-dev1.duckdns.org"
    ```hcl
    install = {
      name = "chad-dev1" # registered chad-dev1 @ duckdns.org
      domain = {
        domainprovider = "duckdns"
        domainname     = "duckdns.org"
        token          = "#####-###-###-###-#########" # the duckdns.org token
      }
    }
    ```
  - cloudflare, web address will appear like "grafana.chad-dev2.chadg.us"
    ```hcl
    install = {
      name = "chad-dev2" # 
      domain = {
        domainprovider = "cloudflare"
        domainname     = "chadg.us" # a cloudflare domain
        token          = "#####-##############" # the cloudflare api token
      }
    }
    ```
- after apply, local file `config` can be used as `KUBECONFIG=./config kubectl get nodes`