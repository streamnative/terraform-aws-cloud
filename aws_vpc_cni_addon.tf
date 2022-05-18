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

data "aws_iam_policy_document" "vpc_cni_sts" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      values   = [format("system:serviceaccount:%s:%s", "kube-system", "aws-node")]
      variable = format("%s:sub", local.oidc_issuer)
    }

    principals {
      type        = "Federated"
      identifiers = [format("arn:%s:iam::%s:oidc-provider/%s", var.aws_partition, local.account_id, local.oidc_issuer)]
    }
  }
}

resource "aws_iam_role" "vpc_cni" {
  count                = var.enable_vpc_cni_addon ? 1 : 0
  name                 = format("%s-aws-cni-role", module.eks.cluster_id)
  description          = format("Role used by IRSA and the KSA aws-node on StreamNative Cloud EKS cluster %s", module.eks.cluster_id)
  assume_role_policy   = data.aws_iam_policy_document.csi_sts.json
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
  tags                 = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
}


resource "aws_iam_role_policy_attachment" "vpc_cni" {
  count      = var.enable_vpc_cni_addon ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni[0].name
}

resource "aws_eks_addon" "vpc_cni" {
  count                    = var.enable_vpc_cni_addon ? 1 : 0
  addon_name               = "vpc-cni"
  addon_version            = var.vpc_cni_addon_version
  cluster_name             = module.eks.cluster_id
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc_cni[0].arn
  tags                     = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
}