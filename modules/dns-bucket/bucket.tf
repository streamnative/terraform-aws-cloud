resource "aws_s3_bucket" "velero" {
  bucket        = format("%s-cluster-backup-snc", var.pm_name)
  tags          = merge({ "Attributes" = "backup", "Name" = "velero-backups" }, local.tags)
  force_destroy = true

  lifecycle {
    ignore_changes = [
      bucket,
    ]
  }
}

resource "aws_s3_bucket" "tiered_storage" {
  bucket        = format("%s-tiered-storage-snc", var.pm_name)
  tags          = merge({ "Attributes" = "tiered-storage" }, local.tags)
  force_destroy = true

  lifecycle {
    ignore_changes = [
      bucket,
    ]
  }
}

data "aws_kms_key" "s3_default" {
  key_id = "alias/aws/s3"
}

locals {
  s3_kms_key = var.s3_encryption_kms_key_arn == "" ? data.aws_kms_key.s3_default.arn : var.s3_encryption_kms_key_arn
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
