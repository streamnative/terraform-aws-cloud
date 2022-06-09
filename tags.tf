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

module "vpc_tags" {
  source = "./modules/eks-vpc-tags"
  count  = var.add_vpc_tags ? 1 : 0

  cluster_name       = var.cluster_name
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
}

# This tags the primary security group which is managed by AWS EKS (and returned to the parent module.eks), not by this module. 
# Without this tag, our permissions prevent us from working with the security group.
# 
# IMPORTANT: If this tag is not present on the SG during a `terraform destroy`, the destroy will fail.
# Terraform tries to remove this tag before destroying module.eks, which means we would no longer be able to manage it.
# Because of this, it's recommended to remove this resource from the *.tfstate PRIOR to running a destroy
resource "aws_ec2_tag" "cluster_security_group" {
  resource_id = module.eks.cluster_primary_security_group_id
  key         = "Vendor"
  value       = "StreamNative"
}