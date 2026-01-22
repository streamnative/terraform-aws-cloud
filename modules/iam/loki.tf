data "aws_iam_policy_document" "loki_sts" {
  provider = aws.target

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
      values   = [format("system:serviceaccount:%s:%s", "sn-system", "loki")]
      variable = format("%s:sub", local.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "loki" {
  provider = aws.target

  name                 = format("%s-loki-s3-role", var.cluster_name)
  description          = format("Role used by IRSA for Loki on StreamNative Cloud EKS cluster %s", var.cluster_name)
  tags                 = local.tags
  path                 = "/StreamNative/"
  permissions_boundary = local.permissions_boundary_arn
  assume_role_policy   = data.aws_iam_policy_document.loki_sts.json
}

resource "aws_iam_role_policy" "irsa_s3_rw" {
  provider = aws.target

  name = "AllowS3ReadWriteAccess"
  role = aws_iam_role.loki.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3ReadWriteAccess",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.loki_bucket}",
          "arn:aws:s3:::${var.loki_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "loki_bucket_admin" {
  provider = aws.source

  bucket = var.loki_bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCrossAccountIRSAAccessS3",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.loki.arn
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.loki_bucket}",
          "arn:aws:s3:::${var.loki_bucket}/*"
        ]
      }
    ]
  })
}