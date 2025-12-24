!--
  ~ Copyright 2025 StreamNative, Inc.
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

# IAM Module
A basic module used to create IAM Roles, Policies for StreamNative Cloud Applications.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.64.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.64.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.csi_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.aws_load_balancer_controller_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cert_manager_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cluster_autoscaler_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.csi_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external_dns_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.karpenter_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.velero_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_bucket"></a> [backup\_bucket](#input\_backup\_bucket) | The name of the s3 bucket to use for backups | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the cluster | `string` | n/a | yes |
| <a name="input_cluster_node_group_iam_role_arn"></a> [cluster\_node\_group\_iam\_role\_arn](#input\_cluster\_node\_group\_iam\_role\_arn) | n/a | `string` | n/a | yes |
| <a name="input_enable_karpenter"></a> [enable\_karpenter](#input\_enable\_karpenter) | Enable karpenter for autoscaling. If set to false, no karpenter resources will be created. | `bool` | `false` | no |
| <a name="input_enable_velero"></a> [enable\_velero](#input\_enable\_velero) | Enable velero for backups. If set to false, no velero resources will be created. | `bool` | `true` | no |
| <a name="input_extra_aws_tags"></a> [extra\_aws\_tags](#input\_extra\_aws\_tags) | extra aws tags to add to any resources | `map(string)` | `{}` | no |
| <a name="input_load_balancer_policy_arn_override"></a> [load\_balancer\_policy\_arn\_override](#input\_load\_balancer\_policy\_arn\_override) | Override the runtime policy arn, otherwise will construct an arn | `string` | `""` | no |
| <a name="input_oidc_issuer"></a> [oidc\_issuer](#input\_oidc\_issuer) | The oidc issuer for the cluster | `string` | n/a | yes |
| <a name="input_permissions_boundary_arn_override"></a> [permissions\_boundary\_arn\_override](#input\_permissions\_boundary\_arn\_override) | Override the permission boundary arn, otherwise will construct an arn | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | n/a | yes |
| <a name="input_runtime_policy_arn_override"></a> [runtime\_policy\_arn\_override](#input\_runtime\_policy\_arn\_override) | Override the runtime policy arn, otherwise will construct an arn | `string` | `""` | no |
| <a name="input_s3_encryption_kms_key_arn"></a> [s3\_encryption\_kms\_key\_arn](#input\_s3\_encryption\_kms\_key\_arn) | KMS key ARN to use for S3 encryption. If not set, the default AWS S3 key will be used. | `string` | `""` | no |
| <a name="input_velero_backup_schedule"></a> [velero\_backup\_schedule](#input\_velero\_backup\_schedule) | The scheduled time for Velero to perform backups. Written in cron expression, defaults to "0 5 * * *" or "at 5:00am every day" | `string` | `"0 5 * * *"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_load_balancer_controller_arn"></a> [aws\_load\_balancer\_controller\_arn](#output\_aws\_load\_balancer\_controller\_arn) | n/a |
| <a name="output_cert_manager_arn"></a> [cert\_manager\_arn](#output\_cert\_manager\_arn) | n/a |
| <a name="output_cluster_autoscaler_arn"></a> [cluster\_autoscaler\_arn](#output\_cluster\_autoscaler\_arn) | n/a |
| <a name="output_csi_arn"></a> [csi\_arn](#output\_csi\_arn) | n/a |
| <a name="output_external_dns_arn"></a> [external\_dns\_arn](#output\_external\_dns\_arn) | n/a |
| <a name="output_karpenter_arn"></a> [karpenter\_arn](#output\_karpenter\_arn) | n/a |
| <a name="output_velero_arn"></a> [velero\_arn](#output\_velero\_arn) | n/a |
<!-- END_TF_DOCS -->