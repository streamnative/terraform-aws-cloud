# Hashicorp Vault resources for AWS
This terraform module creates the resources needed for running hashicorp vault on EKS. This includes a dynamodb table, kms key, and the needed IAM resources for IRSA.

Here is an example usage:

```hcl
module "aws_vault" {
  source = "streamnative/cloud/aws//modules/vault_resources"
  
  cluster_name         = "my-eks-cluster"
  oidc_issuer          = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
  pulsar_namespace     = "my-pulsar-namespace"
  service_account_name = "vault"

  tags = {	  
    Project     = "MyApp"
    Environment = "Prod"
  }
}
```

## Important!
This module uses EKS IAM Roles for Service Accounts (IRSA). In order for these resources to work properly, there are two requirements:

1. You must know the name of the Kubernetes Service Account and the Kubernetes Namespace for your Pulsar Workload. These don't need to exist prior to running this Terraform module, but are necessary for configuring the resources created.
2. You must add an annotation to the Service Account so it can be used by IRSA (IAM Role) created in this module.

The module output includes the AWS ARN for the IAM role created, e.g. `arn:aws:iam::<ACCOUNT_ID>:role/my-eks-cluster-vault-role`. Using that, you can add the oppropriate annotation to the Service Account with `kubectl`:

```shell
kubectl annotate serviceaccount -n <SERVICE_ACCOUNT_NAMESPACE> <SERVICE_ACCOUNT_NAME> \
eks.amazonaws.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/my-eks-cluster-vault-role
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.45.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.45.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.vault_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_role.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_kms_alias.vault_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.vault_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.vault_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vault_sts_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | AWS partition: 'aws', 'aws-cn', or 'aws-us-gov' | `string` | `"aws"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of your EKS cluster and associated resources | `string` | n/a | yes |
| <a name="input_dynamo_billing_mode"></a> [dynamo\_billing\_mode](#input\_dynamo\_billing\_mode) | the billing mode for the dynamodb table that will be created | `string` | `"PAY_PER_REQUEST"` | no |
| <a name="input_dynamo_provisioned_capacity"></a> [dynamo\_provisioned\_capacity](#input\_dynamo\_provisioned\_capacity) | when using "PROVISIONED" billing mode, the specified values will be use for throughput, in all other modes they are ignored | <pre>object({<br>    read  = number,<br>    write = number<br>  })</pre> | <pre>{<br>  "read": 10,<br>  "write": 10<br>}</pre> | no |
| <a name="input_oidc_issuer"></a> [oidc\_issuer](#input\_oidc\_issuer) | The OIDC issuer for the EKS cluster | `string` | n/a | yes |
| <a name="input_pulsar_namespace"></a> [pulsar\_namespace](#input\_pulsar\_namespace) | The kubernetes namespace where Pulsar has been deployed. This is required to set the appropriate policy permissions for IRSA, which grants the Kubernetes Service Account for Vault access to use the IAM role | `string` | n/a | yes |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | The name of the kubernetes service account to by vault. Defaults to "vault" | `string` | `"vault"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags that will be added to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamo_table_arn"></a> [dynamo\_table\_arn](#output\_dynamo\_table\_arn) | The arn of the dynamodb table used by Vault |
| <a name="output_dynamo_table_name"></a> [dynamo\_table\_name](#output\_dynamo\_table\_name) | The name of the dynamodb table used by Vault |
| <a name="output_kms_key_alias_arn"></a> [kms\_key\_alias\_arn](#output\_kms\_key\_alias\_arn) | The arn of the kms key alias used by Vault |
| <a name="output_kms_key_alias_name"></a> [kms\_key\_alias\_name](#output\_kms\_key\_alias\_name) | The name of the kms key alias used by Vault |
| <a name="output_kms_key_target_arn"></a> [kms\_key\_target\_arn](#output\_kms\_key\_target\_arn) | The arn of the kms key used by Vault |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The arn of the IAM role used by Vault. This needs to be annotated on the corresponding Kubernetes Service account in order for IRSA to work properly, e.g. "eks.amazonaws.com/role-arn" : "<this\_arn>" |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the IAM role used by Vault |

