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

terraform {
  required_version = ">=1.0.0"

  required_providers {
    aws = {
      version = ">= 3.45.0"
      source  = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_s3_bucket" "pulsar_backup" {
  acl    = "private"
  bucket = format("%s-backup-%s", var.cluster_name, data.aws_region.current.name)

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = merge({ "Vendor" = "StreamNative", "Attributes" = "backup", "Name" = "velero-backups" }, var.tags)
}

data "aws_iam_policy_document" "backup_base_policy" {
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
      aws_s3_bucket.pulsar_backup.arn,
      "${aws_s3_bucket.pulsar_backup.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "backup_sts_policy" {
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
      values   = [format("system:serviceaccount:%s:%s", var.velero_namespace, var.service_account_name)]
      variable = format("%s:sub", var.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "backup" {
  name                 = format("%s-backup-role", var.cluster_name)
  description          = format("Role assumed by EKS ServiceAccount %s", var.service_account_name)
  assume_role_policy   = data.aws_iam_policy_document.backup_sts_policy.json
  tags                 = merge({ "Vendor" = "StreamNative" }, var.tags)
  path                 = "/StreamNative/"
  permissions_boundary = var.permissions_boundary_arn

  inline_policy {
    name   = format("%s-backup-base-policy", var.cluster_name)
    policy = data.aws_iam_policy_document.backup_base_policy.json
  }
}

resource "helm_release" "velero" {
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
            "bucket" : "${aws_s3_bucket.pulsar_backup.id}"
            "region" : "${data.aws_region.current.name}"
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
          "eks.amazonaws.com/role-arn" : "${aws_iam_role.backup.arn}"
        },
        "podSecurityContext" : {
          "fsGroup" : 65534
        },
        "serviceAccount" : {
          "server" : {
            "name" : "${var.service_account_name}"
            "annotations" : {
              "eks.amazonaws.com/role-arn" : "${aws_iam_role.backup.arn}"
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
