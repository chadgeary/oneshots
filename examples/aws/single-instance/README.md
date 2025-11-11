# oneshots/example/aws/single-instance

A standalone server in AWS, using ansible to configure the system.

## requirements

- access to aws - validate w/ `aws sts get-caller-identity`
- a domain and token from cloudflare
- set in a file called `terraform.tfvars`:
    ```hcl
      install = {
        app    = "mc"
        domain = "chadg.us"
        name   = "chadg"
        network = {
          cidr = "10.100.0.0/20"
        }
        playbook = "pterodactyl-panel.yaml"
      }
    ```
