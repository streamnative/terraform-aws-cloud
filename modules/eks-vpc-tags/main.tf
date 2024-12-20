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

data "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

data "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_ids)
  id    = var.public_subnet_ids[count.index]
}

locals {
  cluster_subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)
  node_pool_private_subnets = [
    for subnet in data.aws_subnet.private_subnets : subnet.id if(length(var.node_pool_azs) == 0 || contains(var.node_pool_azs, subnet.availability_zone))
  ]
  node_pool_public_subnets = [
    for subnet in data.aws_subnet.public_subnets : subnet.id if(length(var.node_pool_azs) == 0 || contains(var.node_pool_azs, subnet.availability_zone))
  ]
}

resource "aws_ec2_tag" "vpc_tag" {
  resource_id = var.vpc_id
  key         = var.cluster_name
  value       = "shared"
}

resource "aws_ec2_tag" "cluster_subnet_tag" {
  count       = length(local.cluster_subnet_ids)
  resource_id = local.cluster_subnet_ids[count.index]
  key         = format("kubernetes.io/cluster/%s", var.cluster_name)
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnet_tag" {
  count       = length(local.node_pool_private_subnets)
  resource_id = local.node_pool_private_subnets[count.index]
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_tag" {
  count       = length(local.node_pool_public_subnets)
  resource_id = local.node_pool_public_subnets[count.index]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}
