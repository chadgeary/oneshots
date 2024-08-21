terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      Name = var.install.name
    }
  }
}

provider "helm" {
  kubernetes {
    client_certificate     = base64decode(yamldecode(module.k3s.this.files["config"].body).users[0].user.client-certificate-data)
    client_key             = base64decode(yamldecode(module.k3s.this.files["config"].body).users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(module.k3s.this.files["config"].body).clusters[0].cluster.certificate-authority-data)
    host                   = yamldecode(module.k3s.this.files["config"].body).clusters[0].cluster.server
  }
}