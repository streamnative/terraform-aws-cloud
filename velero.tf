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
  acl    = "private"
  bucket = format("%s-cluster-backup", var.cluster_name)

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = merge({"Attributes" = "backup", "Name" = "velero-backups" }, local.tags)
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
      identifiers = [format("arn:%s:iam::%s:oidc-provider/%s", var.aws_partition, data.aws_caller_identity.current.account_id, var.oidc_issuer)]
    }
    condition {
      test     = "StringLike"
      values   = [format("system:serviceaccount:%s:%s", var.velero_namespace, "velero")]
      variable = format("%s:sub", var.oidc_issuer)
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
        "credentials" : {
          "useSecret" : "false"
        },
        "configuration" : {
          "provider" : "aws",
          "backupStorageLocation" : {
            "name" : "aws"
            "bucket" : "${aws_s3_bucket.velero.id}"
            "region" : var.region
          }
        },
        "initContainers" : [
          {
            "name" : "velero-plugin-for-aws",
            "image" : "velero/velero-plugin-for-aws:${var.velero_plugin_version}",
            "imagePullPolicy" : "IfNotPresent",
            "volumeMounts" : [
              {
                "mountPath" : "/target",
                "name" : "plugins"
              }
            ]
          }
        ],
        "podAnnotations" : {
          "eks.amazonaws.com/role-arn" : "${aws_iam_role.velero.arn}"
        },
        "podSecurityContext" : {
          "fsGroup" : 65534
        },
        "serviceAccount" : {
          "server" : {
            "name" : "${"velero"}"
            "annotations" : {
              "eks.amazonaws.com/role-arn" : "${aws_iam_role.velero.arn}"
            }
          },
        },
        "schedules" : {
          "cluster-wide-backup" : {
            "schedule" : "${var.velero_backup_schedule}"
            "template" : {
              "excludedNamespaces" : "${var.velero_excluded_namespaces}"
              "storageLocation" : "aws"
              "volumeSnapshotLocations" : ["aws"]
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
}
