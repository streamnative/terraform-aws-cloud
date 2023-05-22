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

resource "aws_s3_bucket" "velero" {
  count  = var.enable_resource_creation ? 1 : 0
  bucket = format("%s-cluster-backup", var.cluster_name)
  tags   = merge({ "Attributes" = "backup", "Name" = "velero-backups" }, local.tags)

  lifecycle {
    ignore_changes = [
      bucket,
    ]
  }
}

moved {
  from = aws_s3_bucket.velero
  to   = aws_s3_bucket.velero[0]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero" {
  bucket = aws_s3_bucket.velero[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.s3_kms_key
      sse_algorithm     = "aws:kms"
    }
  }
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.velero
  to   = aws_s3_bucket_server_side_encryption_configuration.velero[0]
}

data "aws_iam_policy_document" "velero" {
  count = var.enable_resource_creation ? 1 : 0

  statement {
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:List*",
    ]

    resources = [
      aws_s3_bucket.velero[0].arn,
      "${aws_s3_bucket.velero[0].arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "velero_sts" {
  count = var.enable_resource_creation ? 1 : 0

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
      test     = "StringLike"
      values   = [format("system:serviceaccount:%s:%s", var.velero_namespace, "velero")]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "velero" {
  count                = var.enable_resource_creation ? 1 : 0
  name                 = format("%s-velero-backup-role", var.cluster_name)
  description          = format("Role used by IRSA and the KSA velero on StreamNative Cloud EKS cluster %s", var.cluster_name)
  assume_role_policy   = data.aws_iam_policy_document.velero_sts[0].json
  tags                 = local.tags
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
}

// add the move for this now being optional!
moved {
  from = aws_iam_role.velero
  to   = aws_iam_role.velero[0]
}

resource "aws_iam_policy" "velero" {
  count       = (var.enable_resource_creation && var.create_iam_policies) ? 1 : 0
  name        = format("%s-VeleroBackupPolicy", var.cluster_name)
  description = "Policy that defines the permissions for the Velero backup addon service running in a StreamNative Cloud EKS cluster"
  path        = "/StreamNative/"
  policy      = data.aws_iam_policy_document.velero[0].json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "velero" {
  count      = var.enable_resource_creation ? 1 : 0
  policy_arn = var.create_iam_policies ? aws_iam_policy.velero[0].arn : local.default_service_policy_arn
  role       = aws_iam_role.velero[0].name
}

moved {
  from = aws_iam_role_policy_attachment.velero
  to   = aws_iam_role_policy_attachment.velero[0]
}

resource "helm_release" "velero" {
  count           = (var.enable_resource_creation && var.enable_bootstrap) ? 1 : 0
  atomic          = true
  chart           = var.velero_helm_chart_name
  cleanup_on_fail = true
  name            = "velero"
  namespace       = var.velero_namespace
  repository      = var.velero_helm_chart_repository
  timeout         = 300
  version         = var.velero_helm_chart_version
  values = [
    yamlencode(
      {
        credentials = {
          useSecret = "false"
        }
        configuration = {
          provider = "aws"
          backupStorageLocation = {
            name     = "aws"
            provider = "velero.io/aws"
            bucket   = aws_s3_bucket.velero[0].id
            default  = true
            config = {
              region   = var.region
              kmsKeyId = local.s3_kms_key
            }
          }
          volumeSnapshotLocation = {
            name     = "aws"
            provider = "velero.io/aws"
            config = {
              region = var.region
            }
          }
          logLevel = "debug"
        }
        initContainers = [
          {
            name            = "velero-plugin-for-aws",
            image           = "velero/velero-plugin-for-aws:${var.velero_plugin_version}"
            imagePullPolicy = "IfNotPresent"
            volumeMounts = [
              {
                mountPath = "/target"
                name      = "plugins"
              }
            ]
          }
        ]
        podAnnotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.velero[0].arn
        }
        podSecurityContext = {
          fsGroup = 1337
        }
        serviceAccount = {
          server = {
            create = true
            name   = "velero"
            annotations = {
              "eks.amazonaws.com/role-arn" = aws_iam_role.velero[0].arn
            }
          }
        }
        schedules = {
          cluster-wide-backup = {
            schedule = var.velero_backup_schedule
            template = {
              excludedNamespaces      = var.velero_excluded_namespaces
              storageLocation         = "aws"
              volumeSnapshotLocations = ["aws"]
            }
          }
        }
      }
    )
  ]

  dynamic "set" {
    for_each = var.velero_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    kubernetes_namespace.velero[0]
  ]
}


resource "kubernetes_namespace" "velero" {
  count = var.enable_resource_creation ? 1 : 0
  metadata {
    name = var.velero_namespace
  }
}

moved {
  from = kubernetes_namespace.velero
  to   = kubernetes_namespace.velero[0]
}
