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
  name = module.eks_cluster.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.eks_cluster_id
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    config_path = "/path/to/my-sn-platform-cluster-config" # This must match the module input
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  insecure               = false
  config_path            = "/path/to/my-sn-platform-cluster-config" # This must match the module input
}

#######
### Create the StreamNative Platform Cluster
#######
module "sn_platform_cluster" {
  source = "streamnative/cloud/aws"

  cluster_name           = "my-sn-platform-cluster"
  cluster_version        = "1.19"
  kubeconfig_output_path = "/path/to/my-sn-platform-cluster-config" # add this path to the provider configs above

  map_additional_iam_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/my-aws-admin-role"
      username = "management-admin"
      groups   = ["system:masters"]
    }
  ]

  node_pool_instance_types = ["m4.large"]
  node_pool_desired_size   = 3
  node_pool_min_size       = 3
  node_pool_max_size       = 5
  pulsar_namespace         = "pulsar-demo"

  hosted_zone_id     = "Z04554535IN8Z31SKDVQ2"
  public_subnet_ids  = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  private_subnet_ids = ["subnet-vwxyz123", "subnet-efgh242a", "subnet-lmno643b"]
  region             = "us-west-2"
  vpc_id             = "vpc-1234556abcdef"
}