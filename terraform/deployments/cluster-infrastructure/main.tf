# The cluster-infrastructure module is responsible for the AWS resources which
# constitute the EKS cluster.
#
# Any Kubernetes objects which need to be managed via Terraform belong in
# ../cluster-services, not in this module.
#
# See https://github.com/alphagov/govuk-infrastructure/blob/main/docs/architecture/decisions/0003-split-terraform-state-into-separate-aws-cluster-and-kubernetes-resource-phases.md

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
  cluster_services_namespace = "cluster-services"
  secrets_prefix             = "govuk"
  monitoring_namespace       = "monitoring"
  node_security_group_id     = module.eks.cluster_primary_security_group_id
}

provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = {
      cluster              = var.cluster_name
      project              = "replatforming"
      repository           = "govuk-infrastructure"
      terraform_deployment = basename(abspath(path.root))
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = [for s in aws_subnet.eks_control_plane : s.id]
  vpc_id          = data.terraform_remote_state.infra_vpc.outputs.vpc_id

  cluster_endpoint_private_access        = true
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_in_days
  cluster_enabled_log_types = [
    "api", "audit", "authenticator", "controllerManager", "scheduler"
  ]

  create_node_security_group = false # We're just using the cluster primary SG.
  eks_managed_node_group_defaults = {
    ami_type              = "AL2_x86_64"
    capacity_type         = var.workers_default_capacity_type
    subnet_ids            = [for s in aws_subnet.eks_private : s.id]
    create_security_group = false
  }

  eks_managed_node_groups = {
    main = {
      name = var.cluster_name
      # TODO: set iam_role_permissions_boundary
      # TODO: apply provider default_tags to instances; might need to set launch_template_tags.
      desired_size           = var.workers_size_desired
      max_size               = var.workers_size_max
      min_size               = var.workers_size_min
      instance_types         = var.workers_instance_types
      disk_size              = var.node_disk_size
      create_launch_template = false
      launch_template_name   = ""
      # TODO: specify update_config if needed (are the defaults ok?)
      additional_tags = {
        "k8s.io/cluster-autoscaler/enabled"             = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      }
    }
  }
}

# TODO: move these into module.eks once it supports cluster addons, i.e. once
# https://github.com/terraform-aws-modules/terraform-aws-eks/pull/1443 is
# merged.
resource "aws_eks_addon" "cluster_addons" {
  for_each          = toset(["coredns", "kube-proxy", "vpc-cni"])
  addon_name        = each.key
  addon_version     = lookup(var.cluster_addon_versions, each.key, null)
  cluster_name      = module.eks.cluster_id
  resolve_conflicts = "OVERWRITE"
}
