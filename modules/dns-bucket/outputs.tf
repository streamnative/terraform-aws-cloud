output "zone_id" {
  value = local.zone_id
}

output "zone_name" {
  value = local.zone_name
}

output "backup_bucket" {
  value = aws_s3_bucket.velero.bucket
}

output "backup_bucket_kms_key_id" {
  value = local.s3_kms_key
}