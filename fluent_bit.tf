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

# resource "aws_iam_role" "fluent_bit" {
#   count                = var.enable_fluent_bit ? 1 : 0
#   name                 = format("%s-fbit-role", module.eks.cluster_id)
#   description          = format("Role used by IRSA and the KSA aws-for-fluent-bit on StreamNative Cloud EKS cluster %s", module.eks.cluster_id)
#   assume_role_policy   = data.aws_iam_policy_document.fluent_bit_sts.json
#   path                 = "/StreamNative/"
#   permissions_boundary = var.permissions_boundary_arn
#   tags                 = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
# }

# resource "aws_iam_policy" "fluent_bit" {
#   count       = local.create_fluent_bit_policy ? 1 : 0
#   name        = format("%s-fluent_bitPolicy", module.eks.cluster_id)
#   description = "Policy that defines the permissions for the EBS Container Storage Interface Fluent Bit addon service running in a StreamNative Cloud EKS cluster"
#   path        = "/StreamNative/"
#   policy      = data.aws_iam_policy_document.fluent_bit.json
#   tags        = merge({ "Vendor" = "StreamNative" }, var.additional_tags)
# }

# resource "aws_iam_role_policy_attachment" "fluent_bit_managed" {
#   count      = var.enable_fluent_bit ? 1 : 0
#   policy_arn = "arn:${var.aws_partition}:iam::aws:policy/service-role/AmazonEBSfluent_bitDriverPolicy"
#   role       = aws_iam_role.fluent_bit[0].name
# }

# resource "aws_iam_role_policy_attachment" "fluent_bit" {
#   count      = var.enable_fluent_bit ? 1 : 0
#   policy_arn = local.sn_serv_policy_arn != "" ? local.sn_serv_policy_arn : aws_iam_policy.fluent_bit[0].arn
#   role       = aws_iam_role.fluent_bit[0].name
# }

# resource "helm_release" "fluent_bit" {
#   count           = 1 #var.enable_fluent_bit ? 1 : 0
#   atomic          = true
#   chart           = "aws-for-fluent-bit" #var.fluent_bit_helm_chart_name
#   cleanup_on_fail = true
#   name            = "aws-for-fluent-bit"
#   namespace       = "kube-system"
#   repository      = "https://aws.github.io/eks-charts" #var.fluent_bit_helm_chart_repository
#   timeout         = 300
#   version         = "0.1.18" #var.fluent_bit_helm_chart_version
#   values = [yamlencode({
#     cloudWatch = {
#       enabled = true
#       region  = var.region
#       logGroupName = format("/aws/eks/streamnative/%s/logs", module.eks.cluster_id)
#       logRetentionDays = 365
#     }
#     elasticsearch = {
#       enabled = false
#     }
#     firehose = {
#       enabled = false
#     }
#     kinesis = {
#       enabled = false
#     }
#   })]

#   # dynamic "set" {
#   #   for_each = var.fluent_bit_settings
#   #   content {
#   #     name  = set.key
#   #     value = set.value
#   #   }
#   # }

#   depends_on = [
#     module.eks
#   ]
# }