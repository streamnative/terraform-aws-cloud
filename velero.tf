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

resource "aws_s3_bucket" "velero" {
  bucket = format("%s-cluster-backup", var.cluster_name)
  tags   = merge({ "Attributes" = "backup", "Name" = "velero-backups" }, local.tags)

  lifecycle {
    ignore_changes = [
      bucket,
    ]
  }
}

resource "aws_s3_bucket_acl" "velero" {
  bucket = aws_s3_bucket.velero.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero" {
  bucket = aws_s3_bucket.velero.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.s3_kms_key
      sse_algorithm     = "aws:kms"
    }
  }
}

data "aws_iam_policy_document" "velero" {
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
      aws_s3_bucket.velero.arn,
      "${aws_s3_bucket.velero.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "velero_sts" {
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
  name                 = format("%s-velero-backup-role", var.cluster_name)
  description          = format("Role used by IRSA and the KSA velero on StreamNative Cloud EKS cluster %s", var.cluster_name)
  assume_role_policy   = data.aws_iam_policy_document.velero_sts.json
  tags                 = local.tags
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn
}

resource "aws_iam_policy" "velero" {
  count       = var.create_iam_policies ? 1 : 0
  name        = format("%s-VeleroBackupPolicy", var.cluster_name)
  description = "Policy that defines the permissions for the Velero backup addon service running in a StreamNative Cloud EKS cluster"
  path        = "/StreamNative/"
  policy      = data.aws_iam_policy_document.velero.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "velero" {
  policy_arn = var.create_iam_policies ? aws_iam_policy.velero[0].arn : local.default_service_policy_arn
  role       = aws_iam_role.velero.name
}

resource "helm_release" "velero" {
  count           = var.enable_bootstrap ? 1 : 0
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
            bucket   = aws_s3_bucket.velero.id
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
          "eks.amazonaws.com/role-arn" = aws_iam_role.velero.arn
        }
        podSecurityContext = {
          fsGroup = 1337
        }
        serviceAccount = {
          server = {
            create = true
            name   = "velero"
            annotations = {
              "eks.amazonaws.com/role-arn" = aws_iam_role.velero.arn
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
    kubernetes_namespace.velero
  ]
}


resource "kubernetes_namespace" "velero" {
  metadata {
    name = var.velero_namespace
  }
}