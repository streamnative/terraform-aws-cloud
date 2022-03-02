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
      version = ">= 3.45.0"
      source  = "hashicorp/aws"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.2.0"
    }
  }
}

#######
### These data sources are required by the Kubernetes and Helm providers in order to connect to the newly provisioned cluster
#######
data "aws_eks_cluster" "cluster" {
  name = module.sn_cluster.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.sn_cluster.eks_cluster_id
}

data "aws_caller_identity" "current" {}

#######
### The "random_pet" resource and locals block assist in building out the Cluster Name, as well the variables defined
#######

variable "environment" {
  default = "test"
}

variable "region" {
  default = "us-west-2"
}
resource "random_pet" "cluster_name" {
  length = 1
}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  cluster_name = format("sn-%s-%s-%s", random_pet.cluster_name.id, var.environment, var.region)
}

#######
### The providers can be configured to dynamically retrieve the cluster connection configuration after it's been created
#######
provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  insecure               = false
  config_path            = pathexpand("~/.kube/${local.cluster_name}-config")
}

module "vpc" {
  source = "streamnative/cloud/aws//modules/vpc"

  num_azs  = 3              # The number of availabiltiy zones to create.
  vpc_cidr = "10.80.0.0/16" # The module will automatically create subnets based on this cidr and assign them to their respective AZs.
  vpc_name = local.cluster_name
  region   = var.region
}

module "sn_cluster" {
  source = "streamnative/cloud/aws"

  add_vpc_tags             = true # This will add the necessary tags to the VPC resources for Ingress controller auto-discovery 
  cluster_name             = local.cluster_name
  cluster_version          = "1.19"
  hosted_zone_id           = "Z04554535IN8Z31SKDVQ2" # Change this to your hosted zone ID
  kubeconfig_output_path   = pathexpand("~/.kube/${local.cluster_name}-config")
  func_pool_instance_types = ["t3.medium"]
  node_pool_instance_types = ["m5.large"]
  node_pool_desired_size   = 3
  node_pool_min_size       = 1
  node_pool_max_size       = 3

  map_additional_iam_roles = [ # Map your IAM admin role for access within the Cluster
    {
      rolearn  = "arn:aws:iam::123456789012:role/my-aws-admin-role"
      username = "management-admin"
      groups   = ["system:masters"]
    }
  ]

  private_subnet_ids = module.vpc.private_subnet_ids # Use the list of private subnets created by the VPC module
  public_subnet_ids  = module.vpc.public_subnet_ids  # Use the list of public subnets created by the VPC module
  region             = var.region
  vpc_id             = module.vpc.vpc_id # Use the VPC ID created by the VPC module

  depends_on = [
    module.vpc # Adding a dependency on the VPC module allows for a cleaner destroy
  ]
}