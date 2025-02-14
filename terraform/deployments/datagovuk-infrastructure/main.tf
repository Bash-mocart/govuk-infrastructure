terraform {
  backend "s3" {}

  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
  cluster_name  = data.terraform_remote_state.cluster_infrastructure.outputs.cluster_id
  cluster_id    = data.terraform_remote_state.cluster_infrastructure.outputs.cluster_id
  oidc_provider = data.terraform_remote_state.cluster_infrastructure.outputs.cluster_oidc_provider
  services_ns   = data.terraform_remote_state.cluster_infrastructure.outputs.cluster_services_namespace

  default_tags = {
    project              = "replatforming"
    repository           = "govuk-infrastructure"
    terraform_deployment = basename(abspath(path.root))
  }
}

provider "aws" {
  region = "eu-west-1"
  default_tags { tags = local.default_tags }
}

provider "helm" {
  # TODO: If/when TF makes provider configs a first-class language object,
  # reuse the identical config from above.
  kubernetes {
    host                   = data.terraform_remote_state.cluster_infrastructure.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster_infrastructure.outputs.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.cluster_infrastructure.outputs.cluster_id]
    }
  }
}
