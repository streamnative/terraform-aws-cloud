#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

terraform {
  required_version = ">=1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.72.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.7.1"
    }
  }
}

provider "aws" {
  region = local.region
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    insecure               = false
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  insecure               = false
}

data "aws_eks_cluster" "cluster" {
  name = module.sn_cluster.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.sn_cluster.eks_cluster_id
}

data "aws_caller_identity" "current" {}

#######
### Randomly generate a pet name for the cluster. This is useful for development environments, but is not required. Update local.cluster_name if you want to use a more specific name.
#######
resource "random_pet" "cluster_name" {
  length = 1
}

#######
### Set your local variables here
#######
locals {
  account_id       = data.aws_caller_identity.current.account_id
  cluster_name     = format("sn-%s-%s-%s", random_pet.cluster_name.id, local.environment, local.region)
  environment      = "dev" # Environment prefix for the cluster's name
  pulsar_namespace = "pulsar"
  region           = "us-west-2" # Specify the region where the cluster is located
}

#######
### Creates a VPC for the StreamNative Platform EKS cluster
###
### NOTE! NOTE! NOTE!
###
### If you are applying this for the first time, you will need to target the VPC module PRIOR to applying the entire module.
### This is because the subnet IDs passed to the `sn_cluster` module are computed, which a downstream module cannot handle.
###
### Example:
###
### terraform apply -target=module.vpc
###
### After you apply the targeted VPC module, you can then proceed with `terraform apply` on the entire module.
#######
module "vpc" {
  source = "github.com/streamnative/terraform-aws-cloud//modules/vpc?ref=v2.0.1-alpha"

  num_azs  = 3 # A minimum of 2 AWS availability zones is required for EKS clusters
  vpc_cidr = "10.80.0.0/16"
  vpc_name = local.cluster_name
  region   = local.region
}

########
### Creates an EKS cluster for StreamNative Platform
########
module "sn_cluster" {
  source = "github.com/streamnative/terraform-aws-cloud?ref=v2.0.1-alpha"

  cluster_name             = local.cluster_name
  cluster_version          = "1.20"
  hosted_zone_id           = "*" # Specify the hosted zone ID where you want DNS records to be created and managed. This scopes access to the External DNS service.
  kubeconfig_output_path   = "./${local.cluster_name}-config"
  node_pool_instance_types = ["c6i.large"]
  node_pool_desired_size   = 1 # This module creates 1 node pool per private subnet. Based on this configuration, the cluster will have 3 node pools with 1 x c6i.large instance, 3 instances total.
  node_pool_min_size       = 1
  node_pool_max_size       = 5
  public_subnet_ids        = module.vpc.public_subnet_ids
  private_subnet_ids       = module.vpc.private_subnet_ids
  region                   = local.region
  vpc_id                   = module.vpc.vpc_id

  depends_on = [
    module.vpc,
  ]
}

########
### Installs the required operators on the EKS cluster for StreamNative Platform
########
module "sn_bootstrap" {
  source = "github.com/streamnative/terraform-helm-charts?ref=v0.6.1"

  enable_function_mesh_operator = true
  enable_pulsar_operator        = true
  enable_vault_operator         = true

  depends_on = [
    module.sn_cluster
  ]
}

#######
### Creates resources used for tiered storage offloading in Pulsar 
#######
module "sn_tiered_storage_resources" {
  source = "github.com/streamnative/terraform-aws-cloud//modules/tiered-storage-resources?ref=v2.0.1-alpha"

  cluster_name     = module.sn_cluster.eks_cluster_id
  oidc_issuer      = module.sn_cluster.eks_cluster_identity_oidc_issuer_string
  pulsar_namespace = local.pulsar_namespace

  tags = {
    Project     = "StreamNative Platform"
    Environment = local.environment
  }

  depends_on = [
    module.sn_cluster
  ]
}

#######
### Creates resources used by Vault for storing and retrieving secrets related to the Pulsar cluster
#######
module "sn_tiered_storage_vault_resources" {
  source = "github.com/streamnative/terraform-aws-cloud//modules/vault-resources?ref=v2.0.1-alpha"

  cluster_name     = module.sn_cluster.eks_cluster_id
  oidc_issuer      = module.sn_cluster.eks_cluster_identity_oidc_issuer_string
  pulsar_namespace = local.pulsar_namespace

  tags = {
    Project     = "StreamNative Platform"
    Environment = local.environment
  }

  depends_on = [
    module.sn_cluster
  ]
}
