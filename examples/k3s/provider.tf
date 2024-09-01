terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0"
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