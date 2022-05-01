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

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "streamnative_vendor_access" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        var.streamnative_vendor_access_role_arn
      ]
    }
  }
}

locals {
  account_id                = data.aws_caller_identity.current.account_id
  external_id               = (var.external_id != "" ? [{ test : "StringEquals", variable : "sts:ExternalId", values : [var.external_id] }] : [])
  source_identity           = (length(var.source_identities) > 0 ? [{ test : var.source_identity_test, variable : "sts:SourceIdentity", values : var.source_identities }] : [])
  assume_conditions         = concat(local.external_id, local.source_identity)
  bootstrap_policy_path     = var.use_runtime_policy ? "${path.module}/files/bootstrap_role_iam_policy_runtime.json.tpl" : "${path.module}/files/bootstrap_role_iam_policy.json.tpl"
  perm_boundary_policy_path = var.use_runtime_policy ? "${path.module}/files/permission_boundary_iam_policy_runtime.json.tpl" : "${path.module}/files/permission_boundary_iam_policy.json.tpl"
  arn_like_vpcs             = formatlist("\"arn:aws:ec2:%s:%s:vpc/%s\"", var.region, local.account_id, var.runtime_vpc_allowed_ids)
  arn_like_vpcs_str         = format("[%s]", join(",", local.arn_like_vpcs))
  tag_set                   = merge({ Vendor = "StreamNative", SNVersion = var.sn_policy_version }, var.tags)
}

data "aws_iam_policy_document" "streamnative_control_plane_access" {
  statement {
    sid     = "AllowStreamNativeVendorAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        var.streamnative_vendor_access_role_arn,
        var.streamnative_control_plane_role_arn
      ]
    }
    dynamic "condition" {
      for_each = local.assume_conditions
      content {
        test     = condition.value["test"]
        values   = condition.value["values"]
        variable = condition.value["variable"]
      }
    }
  }

  statement {
    sid     = "AllowStreamNativeControlPlaneAccess"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "accounts.google.com"
      ]
    }
    condition {
      test     = "StringEquals"
      values   = [var.streamnative_google_account_id]
      variable = "accounts.google.com:aud"
    }
  }
}

######
#-- Create the IAM Permission Boundary used by all StreamNative
#-- IAM Resources. This restricts what type of access we have
#-- within your AWS Account and is applied to all our IAM Roles
######
resource "aws_iam_policy" "permission_boundary" {
  name        = "StreamNativeCloudPermissionBoundary"
  description = "This policy sets the permission boundary for StreamNative's vendor access. It defines the limits of what StreamNative can do within this AWS account."
  path        = "/StreamNative/"
  policy = templatefile(local.perm_boundary_policy_path,
    {
      account_id = local.account_id
      region     = var.region
  })
  tags = local.tag_set
}

resource "local_file" "permission_boundary_policy" {
  count = var.write_policy_files ? 1 : 0
  content = templatefile(local.perm_boundary_policy_path,
    {
      account_id = local.account_id
      region     = var.region
  })
  filename = "permission_boundary_policy.json"
}

######
#-- Create the IAM role for bootstraping of the StreamNative Cloud
#-- This role is only needed for the initial StreamNative Cloud
#-- deployment to an AWS account, or when it is being removed.
######
resource "aws_iam_role" "bootstrap_role" {
  count                = var.create_bootstrap_role ? 1 : 0
  name                 = "StreamNativeCloudBootstrapRole"
  description          = "This role is used to bootstrap the StreamNative Cloud within the AWS account. It is limited in scope to the attached policy and also the permission boundary."
  assume_role_policy   = data.aws_iam_policy_document.streamnative_vendor_access.json
  path                 = "/StreamNative/"
  permissions_boundary = aws_iam_policy.permission_boundary.arn
  tags                 = local.tag_set
}

resource "aws_iam_policy" "bootstrap_policy" {
  count       = var.create_bootstrap_role ? 1 : 0
  name        = "StreamNativeCloudBootstrapPolicy"
  description = "This policy sets the minimum amount of permissions needed by the StreamNativeCloudBootstrapRole to bootstrap the StreamNative Cloud deployment."
  path        = "/StreamNative/"
  policy = templatefile(local.bootstrap_policy_path,
    {
      account_id = local.account_id
      region     = var.region
      vpc_ids    = local.arn_like_vpcs_str
  })
  tags = local.tag_set
}

resource "local_file" "bootstrap_policy" {
  count = var.write_policy_files ? 1 : 0
  content = templatefile(local.bootstrap_policy_path,
    {
      account_id = local.account_id
      region     = var.region
      vpc_ids    = local.arn_like_vpcs_str
  })
  filename = "bootstrap_policy.json"
}

resource "aws_iam_role_policy_attachment" "bootstrap_policy" {
  count      = var.create_bootstrap_role ? 1 : 0
  policy_arn = aws_iam_policy.bootstrap_policy[0].arn
  role       = aws_iam_role.bootstrap_role[0].name
}

######
#-- Create the IAM role for the management of the StreamNative Cloud
#-- This role is used by StreamNative for management and troubleshooting
#-- of the managed deployment.
######
resource "aws_iam_policy" "management_role" {
  name        = "StreamNativeCloudManagementPolicy"
  description = "This policy sets the limits for the management role needed for StreamNative's vendor access."
  path        = "/StreamNative/"
  policy = templatefile("${path.module}/files/management_role_iam_policy.json.tpl",
    {
      account_id = data.aws_caller_identity.current.account_id
      region     = var.region
  })
  tags = local.tag_set
}

resource "local_file" "management_policy" {
  count = var.write_policy_files ? 1 : 0
  content = templatefile("${path.module}/files/management_role_iam_policy.json.tpl",
    {
      account_id = data.aws_caller_identity.current.account_id
      region     = var.region
  })
  filename = "management_policy.json"
}

resource "aws_iam_role" "management_role" {
  name                 = "StreamNativeCloudManagementRole"
  description          = "This role is used by StreamNative for the day to day management of the StreamNative Cloud deployment."
  assume_role_policy   = data.aws_iam_policy_document.streamnative_control_plane_access.json
  path                 = "/StreamNative/"
  permissions_boundary = aws_iam_policy.permission_boundary.arn
  tags                 = local.tag_set
}

resource "aws_iam_role_policy_attachment" "management_role" {
  policy_arn = aws_iam_policy.management_role.arn
  role       = aws_iam_role.management_role.name
}

