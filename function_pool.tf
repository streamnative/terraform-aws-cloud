# #
# # Licensed to the Apache Software Foundation (ASF) under one
# # or more contributor license agreements.  See the NOTICE file
# # distributed with this work for additional information
# # regarding copyright ownership.  The ASF licenses this file
# # to you under the Apache License, Version 2.0 (the
# # "License"); you may not use this file except in compliance
# # with the License.  You may obtain a copy of the License at
# #
# #   http://www.apache.org/licenses/LICENSE-2.0
# #
# # Unless required by applicable law or agreed to in writing,
# # software distributed under the License is distributed on an
# # "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# # KIND, either express or implied.  See the License for the
# # specific language governing permissions and limitations
# # under the License.
# #

# module "func_role_label" {
#   source              = "cloudposse/label/null"
#   version             = "0.24.1"
#   attributes          = ["func-base", local.func_pool_sa_id]
#   regex_replace_chars = "/[^-a-zA-Z0-9@_]/"

#   context = module.this.context
# }

# resource "kubernetes_namespace" "func_pool" {
#   count = var.enable_func_pool == true ? 1 : 0
#   metadata {
#     name = var.func_pool_namespace
#   }
#   depends_on = [
#     module.eks
#   ]
# }

# data "aws_iam_policy_document" "func_pool_sa" {
#   statement {
#     actions = [
#       "sts:AssumeRole"
#     ]
#     resources = var.func_pool_allowed_role_arns
#   }
# }

# data "aws_iam_policy_document" "func_pool_sts" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }

#   statement {
#     actions = [
#       "sts:AssumeRoleWithWebIdentity"
#     ]
#     effect = "Allow"
#     principals {
#       type        = "Federated"
#       identifiers = [format("arn:%s:iam::%s:oidc-provider/%s", var.aws_partition, local.account_id, local.oidc_issuer)]
#     }
#     condition {
#       test     = "StringLike"
#       values   = [format("system:serviceaccount:%s:%s", var.func_pool_namespace, var.func_pool_sa_name)]
#       variable = format("%s:sub", local.oidc_issuer)
#     }
#   }
# }

# resource "aws_iam_role" "func_pool" {
#   count              = var.enable_func_pool == true ? 1 : 0
#   name               = format("%s-func-pool-role", module.eks.cluster_id)
#   description        = format("Role assumed by EKS ServiceAccount %s", local.func_pool_sa_id)
#   assume_role_policy = data.aws_iam_policy_document.func_pool_sts.json
#   tags               = module.func_role_label.tags

#   inline_policy {
#     name   = format("%s-func-pool-policy", module.eks.cluster_id)
#     policy = data.aws_iam_policy_document.func_pool_sa.json
#   }

#   managed_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
#     "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
#     "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   ]
# }
