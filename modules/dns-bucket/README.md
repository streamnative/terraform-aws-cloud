<!--
  ~ Copyright 2023 StreamNative, Inc.
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~     http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
-->

# DNS and Bucket Module
A basic module used to create Route53 Zone and S3 Buckets.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.6.0 |
| <a name="provider_aws.source"></a> [aws.source](#provider\_aws.source) | 6.6.0 |
| <a name="provider_aws.target"></a> [aws.target](#provider\_aws.target) | 6.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.delegate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_s3_bucket.loki](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_kms_key.s3_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_route53_zone.sn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_location"></a> [bucket\_location](#input\_bucket\_location) | The location of the bucket | `string` | n/a | yes |
| <a name="input_custom_dns_zone_id"></a> [custom\_dns\_zone\_id](#input\_custom\_dns\_zone\_id) | if specified, then a streamnative zone will not be created, and this zone will be used instead. Otherwise, we will provision a new zone and delegate access | `string` | `""` | no |
| <a name="input_custom_dns_zone_name"></a> [custom\_dns\_zone\_name](#input\_custom\_dns\_zone\_name) | must be passed if custom\_dns\_zone\_id is passed, this is the zone name to use | `string` | `""` | no |
| <a name="input_enable_loki"></a> [enable\_loki](#input\_enable\_loki) | Enable loki storage bucket creation | `bool` | `false` | no |
| <a name="input_extra_aws_tags"></a> [extra\_aws\_tags](#input\_extra\_aws\_tags) | Additional to apply to the resources. Note that this module sets the tags Name, Type, and Vendor by default. They can be overwritten, but it is not recommended. | `map(string)` | `{}` | no |
| <a name="input_parent_zone_name"></a> [parent\_zone\_name](#input\_parent\_zone\_name) | The parent zone in which we create the delegation records | `string` | n/a | yes |
| <a name="input_pm_name"></a> [pm\_name](#input\_pm\_name) | The name of the poolmember, for new clusters, this should be like `pm-<xxxxx>` | `string` | n/a | yes |
| <a name="input_pm_namespace"></a> [pm\_namespace](#input\_pm\_namespace) | The namespace of the poolmember | `string` | n/a | yes |
| <a name="input_s3_encryption_kms_key_arn"></a> [s3\_encryption\_kms\_key\_arn](#input\_s3\_encryption\_kms\_key\_arn) | KMS key ARN to use for S3 encryption. If not set, the default AWS S3 key will be used. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backup_bucket"></a> [backup\_bucket](#output\_backup\_bucket) | n/a |
| <a name="output_backup_bucket_kms_key_id"></a> [backup\_bucket\_kms\_key\_id](#output\_backup\_bucket\_kms\_key\_id) | n/a |
| <a name="output_loki_bucket"></a> [loki\_bucket](#output\_loki\_bucket) | n/a |
| <a name="output_tiered_storage_bucket"></a> [tiered\_storage\_bucket](#output\_tiered\_storage\_bucket) | n/a |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | n/a |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | n/a |
<!-- END_TF_DOCS -->