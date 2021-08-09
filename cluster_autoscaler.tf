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

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = format("%s-cluster-autoscaler-policy", module.eks.cluster_id)
  description = "Provides EC2 ASG access for cluster autoscaling"
  policy      = data.aws_iam_policy_document.worker_autoscaling.json
}

data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster/${module.eks.cluster_id}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name                = format("%s-cluster-autoscaler-role", module.eks.cluster_id)
  description         = format("Allows %s assume role permissions in %s", module.eks.cluster_id, var.region)
  managed_policy_arns = [aws_iam_policy.cluster_autoscaler.arn]

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${local.account_id}:oidc-provider/${local.oidc_issuer}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${local.oidc_issuer}:aud" : "sts.amazonaws.com",
            "${local.oidc_issuer}:sub" : "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })
}

resource "helm_release" "cluster_autoscaler" {
  atomic          = true
  chart           = var.cluster_autoscaler_helm_chart_name
  cleanup_on_fail = true
  name            = "cluster-autoscaler"
  namespace       = "kube-system"
  repository      = var.cluster_autoscaler_helm_chart_repository
  timeout         = 600
  version         = var.cluster_autoscaler_helm_chart_version

  dynamic "set" {
    for_each = var.cluster_autoscaler_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  # Keep this issue in mind when running autoscaler, especially if you are seeing OOMKilled errors.
  # https://github.com/kubernetes/autoscaler/issues/3506
  values = [
    yamlencode({
      "autoDiscovery" : {
        "clusterName" : "${module.eks.cluster_id}",
      }
      "awsRegion" : "${var.region}"
      "cloudProvider" : "aws"
      "extraArgs" : {
        "balance-similar-node-groups" : true,
        "expander" : "least-waste",
        "node-group-auto-discovery" : "asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${module.eks.cluster_id}"
        "skip-nodes-with-system-pods" : false,
        "skip-nodes-with-local-storage" : false,
      }
      "extraVolumes" : [
        {
          "name" : "ssl-certs",
          "hostPath" : {
            "path" : "/etc/ssl/certs/ca-bundle.crt"
          }
        }
      ]
      "extraVolumeMounts" : [
        {
          "name" : "ssl-certs",
          "mountPath" : "/etc/ssl/certs/ca-certificates.crt",
          "readOnly" : true
        }
      ]
      "rbac" : {
        "create" : true,
        "pspEnabled" : true,
        "serviceAccount" : {
          "annotations" : {
            "eks.amazonaws.com/role-arn" : "${aws_iam_role.cluster_autoscaler.arn}"
          },
          "create" : true,
          "name" : "cluster-autoscaler",
          "automountServiceAccountToken" : true
        }
      }
      "replicaCount" : "1"
      "resources" : {
        "limits" : {
          "cpu" : "100m",
          "memory" : "500Mi"
        },
        "requests" : {
          "cpu" : "100m",
          "memory" : "500Mi"
        }
      }
    })
  ]
}
