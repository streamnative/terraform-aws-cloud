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

#######
### This section contains configurable inputs to satisfy your cluster specifications
#######
locals {
  availability_zones = 3     # Number of AZs to use. EKS requires a minimum of 2.
  desired_num_nodes  = 3     # The desired node count for the node groups. This module creates a node group for each availability zone.
  environment        = "dev" # This is used for naming of resources created by this module.
  hosted_zone_id     = "*"   # Specify the hosted zone ID where you want DNS records to be created and managed. This scopes access to the External DNS service.
  instance_type      = ["c6i.xlarge"]
  max_num_nodes      = 12             # The maximum number of nodes to create across all node groups. This module creates a node group for each availability zone.
  pulsar_namespace   = "pulsar"       # The module doesn't create a namespace for Pulsar, but it uses it for scoping access to the Tiered Storage Bucket
  region             = "us-west-2"    # Specify the region where the cluster is located
  vpc_cidr           = "10.80.0.0/16" # If creating a VPC, specify the CIDR range to use
}

provider "aws" {
  region = local.region
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

data "aws_eks_cluster" "cluster" {
  name = module.sn_cluster.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.sn_cluster.eks_cluster_name
}

data "aws_caller_identity" "current" {}

#######
### Randomly generate a pet name for the cluster. This is useful for development environments, but is not required. Update local.cluster_name if you want to use a more specific name.
#######
resource "random_pet" "cluster_name" {
  length = 1
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
  source = "github.com/streamnative/terraform-aws-cloud//modules/vpc?ref=v2.2.4-alpha"

  num_azs  = local.availability_zones
  vpc_cidr = local.vpc_cidr
  vpc_name = local.cluster_name
  region   = local.region
}

########
### Creates an EKS cluster for StreamNative Platform
########
module "sn_cluster" {
  source = "github.com/streamnative/terraform-aws-cloud?ref=v2.2.4-alpha"

  cluster_name             = local.cluster_name
  cluster_version          = "1.20"
  hosted_zone_id           = local.hosted_zone_id
  map_additional_iam_roles = local.cluster_role_mapping
  node_pool_instance_types = local.instance_type
  node_pool_desired_size   = floor(local.desired_num_nodes / length(module.vpc.private_subnet_ids)) # Floor here to keep the desired count lower, autoscaling will take care of the rest  
  node_pool_min_size       = 1
  node_pool_max_size       = ceil(local.max_num_nodes / length(module.vpc.private_subnet_ids)) # Ceiling here to keep the upper limits on the high end 
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
  source = "github.com/streamnative/terraform-helm-charts?ref=v0.8.1"

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
  source = "github.com/streamnative/terraform-aws-cloud//modules/tiered-storage-resources?ref=v2.2.4-alpha"

  cluster_name     = module.sn_cluster.eks_cluster_name
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
  source = "github.com/streamnative/terraform-aws-cloud//modules/vault-resources?ref=v2.2.4-alpha"

  cluster_name     = module.sn_cluster.eks_cluster_name
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

### Helpers
locals {
  cluster_name = format("sn-%s-%s-%s", random_pet.cluster_name.id, local.environment, local.region)
  cluster_role_mapping = [
    {
      rolearn  = module.sn_cluster.worker_iam_role_arn # The module creates IAM resources with the path "/StreamNative/". However the parent module is configured to remove the path from the worker nodes in the role mapping, which causes an erroneous node group health error in the EKS console.
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]
}

output "cleanup_for_destroying_cluster" {
  description = "If you need to DESTROY the cluster, this command to clean up k8s resources from the tfstate, allowing you to cleanly proceed with a `terraform destroy`"
  value       = "for i in $(tf state list | grep -E 'kubernetes|helm'); do tf state rm $i; done"
}

output "connect_to_cluster" {
  value = format("aws eks update-kubeconfig --name %s --kubeconfig ~/.kube/config --region %s", module.sn_cluster.eks_cluster_name, local.region)
}

output "eks_cluster_name" {
  value = module.sn_cluster.eks_cluster_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "worker_iam_role_arn" {
  value = module.sn_cluster.worker_iam_role_arn
}
