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

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DesribedNodegroup",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${module.eks.cluster_id}"
      values   = ["owned"]
    }
  }
}

data "aws_iam_policy_document" "cluster_autoscaler_sts" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [format("arn:%s:iam::%s:oidc-provider/%s", local.aws_partition, local.account_id, local.oidc_issuer)]
    }
    condition {
      test     = "StringEquals"
      values   = [format("system:serviceaccount:%s:%s", "kube-system", "cluster-autoscaler")]
      variable = format("%s:sub", local.oidc_issuer)
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = format("%s:aud", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name                 = format("%s-ca-role", module.eks.cluster_id)
  description          = format("Role used by IRSA and the KSA cluster-autoscaler on StreamNative Cloud EKS cluster %s", module.eks.cluster_id)
  assume_role_policy   = data.aws_iam_policy_document.cluster_autoscaler_sts.json
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count       = var.create_iam_policies ? 1 : 0
  name        = format("%s-ClusterAutoscalerPolicy", module.eks.cluster_id)
  description = "Policy that defines the permissions for the Cluster Autoscaler addon service running in a StreamNative Cloud EKS cluster"
  path        = "/StreamNative/"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = var.create_iam_policies ? aws_iam_policy.cluster_autoscaler[0].arn : local.default_service_policy_arn
  role       = aws_iam_role.cluster_autoscaler.name
}

############
# Keep this issue in mind when running CA on AWS/EKS, especially if you are seeing OOMKilled errors on the CA pod.
# https://github.com/kubernetes/autoscaler/issues/3506
#
# Also Refer to the CA FAQ for troubleshooting or configuration options
# https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-the-parameters-to-ca
############

locals {
  k8s_to_autoscaler_version = {
    "1.18" = "v1.18.3",
    "1.19" = "v1.19.2",
    "1.20" = "v1.20.1",
    "1.21" = "v1.21.1",
    "1.22" = "v1.22.1",
    "1.23" = "v1.23.0"
  }

}
resource "helm_release" "cluster_autoscaler" {
  count           = var.enable_bootstrap ? 1 : 0
  atomic          = true
  chart           = var.cluster_autoscaler_helm_chart_name
  cleanup_on_fail = true
  name            = "cluster-autoscaler"
  namespace       = "kube-system"
  repository      = var.cluster_autoscaler_helm_chart_repository
  timeout         = 120
  version         = var.cluster_autoscaler_helm_chart_version
  values = [yamlencode({
    autoDiscovery = {
      clusterName = module.eks.cluster_id
    }
    awsRegion     = var.region
    cloudProvider = "aws"
    extraArgs = {
      balance-similar-node-groups   = true
      expander                      = "random"
      node-group-auto-discovery     = format("asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/%s", module.eks.cluster_id)
      skip-nodes-with-system-pods   = false
      skip-nodes-with-local-storage = false
    }
    extraVolumes = [
      {
        name = "ssl-certs"
        hostPath = {
          path = "/etc/ssl/certs/ca-bundle.crt"
        }
      }
    ]
    extraVolumeMounts = [
      {
        name      = "ssl-certs"
        mountPath = "/etc/ssl/certs/ca-certificates.crt"
        readOnly  = true
      }
    ]
    image = {
      tag = lookup(local.k8s_to_autoscaler_version, var.cluster_version, "v1.21.1") # image.tag defaults to the version corresponding to var.cluster_version's default value and must manually be updated
    }
    rbac = {
      create     = true
      pspEnabled = true
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler.arn
        },
        create                       = true
        name                         = "cluster-autoscaler"
        automountServiceAccountToken = true
      }
    }
    replicaCount = "2"
    resources = {
      limits = {
        cpu    = "200m"
        memory = "1Gi"
      },
      requests = {
        cpu    = "100m"
        memory = "500Mi"
      }
    }
    })
  ]

  dynamic "set" {
    for_each = var.cluster_autoscaler_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    module.eks
  ]
}
