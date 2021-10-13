# Tiered Storage for AWS
This Terraform module creates the resources needed for tiered storage offloading in Pulsar. This includes an encrypted and private S3 bucket and the IAM resources for IRSA.

Here is an example usage:

```hcl
module "tiered_storage" {
  source = "streamnative/cloud/aws//modules/tiered_storage"

  cluster_name         = "my-eks-cluster"
  oidc_issuer          = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
  pulsar_namespace     = "my-pulsar-namespace"
  service_account_name = "my-pulsar-service-account"

  tags = {	  
    Project     = "MyApp"
    Environment = "Prod"
  }
}
```

## Important!
This module uses EKS IAM Roles for Service Accounts (IRSA). In order for these resources to work properly, there are two requirements:

1. You must know the name of the Kubernetes Service Account and the Kubernetes namespace for your Pulsar workload. These don't need to exist prior to running this Terraform module, but are necessary for the resources to work properly.
2. You must add an annotation to the Service Account so it can be used by IRSA (IAM Role) created in this module.

The module output includes the AWS ARN for the IAM role created. Using that, you can add the oppropriate annotation to the Service Account using `kubectl`:

```shell
kubectl annotate serviceaccount -n <SERVICE_ACCOUNT_NAMESPACE> <SERVICE_ACCOUNT_NAME> \
eks.amazonaws.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/my-eks-cluster-tiered-storage-role
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.61.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.61.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.tiered_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.tiered_storage_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition: 'aws', 'aws-cn', or 'aws-us-gov' | `string` | `"aws"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of your EKS cluster and associated resources | `string` | n/a | yes |
| <a name="input_create_iam_policy_for_tiered_storage"></a> [create\_iam\_policy\_for\_tiered\_storage](#input\_create\_iam\_policy\_for\_tiered\_storage) | Whether to create the IAM policy used by Pulsar's tiered storage offloading. For enhanced security, we allow for these IAM policies to be created seperately from this module. Defaults to "true". If set to "false", you must provide the ARN for the IAM policy needed for Velero. | `bool` | `true` | no |
| <a name="input_iam_policy_arn"></a> [iam\_policy\_arn](#input\_iam\_policy\_arn) | The arn for the IAM policy used for Pulsar's tiered storage offloading. For enhanced security, we allow for IAM policies used by cluster addon services to be created seperately from this module. This is only required if the input "create\_iam\_policy\_for\_tiered\_storage" is set to "false". If created elsewhere, the expected name of the policy is "StreamNativeCloudVeleroBackupPolicy". | `string` | `null` | no |
| <a name="input_oidc_issuer"></a> [oidc\_issuer](#input\_oidc\_issuer) | The OIDC issuer for the EKS cluster | `string` | n/a | yes |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | If required, provide the ARN of the IAM permissions boundary to use for restricting StreamNative's vendor access. | `string` | `null` | no |
| <a name="input_pulsar_namespace"></a> [pulsar\_namespace](#input\_pulsar\_namespace) | The kubernetes namespace where Pulsar has been deployed. This is required to set the appropriate policy permissions for IRSA, which grants the Kubernetes Service Account access to use the IAM role | `string` | n/a | yes |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | The name of the kubernetes service account to by tiered storage offloading. Defaults to "pulsar". This is required to set the appropriate policy permissions for IRSA, which grants the Kubernetes Service Account access to use the IAM role | `string` | `"pulsar"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be added to the bucket and corresponding resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The arn of the role used for Pulsar's tiered storage offloading. This needs to be annotated on the corresponding Kubernetes Service account in order for IRSA to work properly, e.g. "eks.amazonaws.com/role-arn" : "<this\_arn>" |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the role used for Pulsar's tiered storage offloading |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | The name of the bucket used for Pulsar's tiered storage offloading |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The arn of the bucket used for Pulsar's tiered storage offloading |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The arn of the role used for Pulsar's tiered storage offloading. This needs to be annotated on the corresponding Kubernetes Service account in order for IRSA to work properly, e.g. "eks.amazonaws.com/role-arn" : "<this\_arn>" |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the role used for Pulsar's tiered storage offloading |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | The name of the bucket used for Pulsar's tiered storage offloading |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The arn of the bucket used for Pulsar's tiered storage offloading |
