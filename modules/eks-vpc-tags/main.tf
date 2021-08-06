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

locals {
  cluster_subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)
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
  count       = length(var.private_subnet_ids)
  resource_id = var.private_subnet_ids[count.index]
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_tag" {
  count       = length(var.private_subnet_ids)
  resource_id = var.public_subnet_ids[count.index]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}
