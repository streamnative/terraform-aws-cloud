## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.45.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.45.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [helm_release.velero](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.velero](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.velero_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition: 'aws', 'aws-cn', or 'aws-us-gov' | `string` | `"aws"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of your EKS cluster and associated resources | `string` | n/a | yes |
| <a name="input_create_iam_policy_for_velero"></a> [create\_iam\_policy\_for\_velero](#input\_create\_iam\_policy\_for\_velero) | Whether to create the IAM policy used by the Velero backup addon service running within the EKS cluster. For enhanced security, we allow for these IAM policies to be created seperately from this module. Defaults to "true". If set to "false", you must provide the ARN for the IAM policy needed for Velero. | `bool` | `true` | no |
| <a name="input_oidc_issuer"></a> [oidc\_issuer](#input\_oidc\_issuer) | The OIDC issuer for the EKS cluster | `string` | n/a | yes |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | If required, provide the ARN of the IAM permissions boundary to use for restricting StreamNative's vendor access | `string` | `null` | no |
| <a name="input_pulsar_namespace"></a> [pulsar\_namespace](#input\_pulsar\_namespace) | The namespace where Pulsar is deployed. This is required in order for Velero to backup Pulsar | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be added to the bucket and corresponding resources | `map(string)` | `{}` | no |
| <a name="input_velero_backup_schedule"></a> [velero\_backup\_schedule](#input\_velero\_backup\_schedule) | The scheduled time for Velero to perform backups. Written in cron expression, defaults to "0 5 * * *" or "at 5:00am every day" | `string` | `"0 5 * * *"` | no |
| <a name="input_velero_excluded_namespaces"></a> [velero\_excluded\_namespaces](#input\_velero\_excluded\_namespaces) | A comma-separated list of namespaces to exclude from Velero backups. Defaults are set to ["default", "kube-system", "operators", "olm"]. | `list(string)` | <pre>[<br>  "kube-system",<br>  "default",<br>  "operators",<br>  "olm"<br>]</pre> | no |
| <a name="input_velero_helm_chart_name"></a> [velero\_helm\_chart\_name](#input\_velero\_helm\_chart\_name) | The name of the Helm chart to use for Velero | `string` | `"velero"` | no |
| <a name="input_velero_helm_chart_repository"></a> [velero\_helm\_chart\_repository](#input\_velero\_helm\_chart\_repository) | The repository containing the Helm chart to use for velero | `string` | `"https://vmware-tanzu.github.io/helm-charts"` | no |
| <a name="input_velero_helm_chart_version"></a> [velero\_helm\_chart\_version](#input\_velero\_helm\_chart\_version) | The version of the Helm chart to use for Velero The current version can be found in github: https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/Chart.yaml | `string` | `"2.23.12"` | no |
| <a name="input_velero_namespace"></a> [velero\_namespace](#input\_velero\_namespace) | The kubernetes namespace where Velero should be deployed. This is required to set the appropriate policy permissions for IRSA, which grants the Kubernetes Service Account access to use the IAM role. Defaults to "sn-system" | `string` | `"sn-system"` | no |
| <a name="input_velero_plugin_version"></a> [velero\_plugin\_version](#input\_velero\_plugin\_version) | Which version of the velero-plugin-for-aws to use. Defaults to v1.3.0 | `string` | `"v1.3.0"` | no |
| <a name="input_velero_policy_arn"></a> [velero\_policy\_arn](#input\_velero\_policy\_arn) | The arn for the IAM policy used by the Velero backup addon service. For enhanced security, we allow for IAM policies used by cluster addon services to be created seperately from this module. This is only required if the input "create\_iam\_policy\_for\_velero" is set to "false". If created elsewhere, the expected name of the policy is "StreamNativeCloudVeleroBackupPolicy". | `string` | `null` | no |
| <a name="input_velero_settings"></a> [velero\_settings](#input\_velero\_settings) | Additional settings which will be passed to the Helm chart values for Velero. See https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero for available options | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The arn of the role used for Velero backups for Pulsar. This needs to be annotated on the corresponding Kubernetes Service account in order for IRSA to work properly, e.g. "eks.amazonaws.com/role-arn" : "<this\_arn>" |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the role used for Velero backups for Pulsar |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | The name of the bucket used for Velero backups of Pulsar |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The arn of the bucket used for Velero backups for Pulsar |
