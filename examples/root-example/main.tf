# Copyright 2023 StreamNative, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  cluster_name = "sn-aws"
}

variable "region" {
  type        = string
  description = "The region of AWS"
}

#######
### These data sources are required by the Kubernetes and Helm providers in order to connect to the newly provisioned cluster
#######
data "aws_eks_cluster" "cluster" {
  name = module.sn_cluster.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.sn_cluster.eks_cluster_name
}

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
}

#######
### Create the StreamNative Platform Cluster
#######
module "sn_cluster" {
  source = "../.."

  add_vpc_tags             = true # This will add the necessary tags to the VPC resources for Ingress controller auto-discovery 
  cluster_name             = local.cluster_name
  cluster_version          = "1.20"
  hosted_zone_id           = "Z04554535IN8Z31SKDVQ2" # Change this to your hosted zone ID
  node_pool_instance_types = ["c6i.xlarge"]
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

  public_subnet_ids  = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  private_subnet_ids = ["subnet-vwxyz123", "subnet-efgh242a", "subnet-lmno643b"]
  region             = var.region
  vpc_id             = "vpc-1234556abcdef"
}
