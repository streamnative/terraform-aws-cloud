## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.61.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.61.0 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.bootstrap_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.management_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.bootstrap_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.management_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.bootstrap_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.management_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.streamnative_vendor_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [template_file.bootstrap_role](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.management_role](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.permission_boundary](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_bootstrap_role"></a> [create\_bootstrap\_role](#input\_create\_bootstrap\_role) | Whether or not to create the bootstrap role, which is used by StreamNative for the initial deployment of the StreamNative Cloud | `string` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region where your instance of StreamNative Cloud is deployed, i.e. "us-west-2" | `string` | n/a | yes |
| <a name="input_streamnative_vendor_access_role_arn"></a> [streamnative\_vendor\_access\_role\_arn](#input\_streamnative\_vendor\_access\_role\_arn) | The arn for the IAM principle (role) provided by StreamNative. This role is used exclusively by StreamNative (with strict permissions) for vendor access into your AWS account | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags to apply to the resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bootstrap_role_arn"></a> [bootstrap\_role\_arn](#output\_bootstrap\_role\_arn) | the arn of the role |
| <a name="output_management_role_arn"></a> [management\_role\_arn](#output\_management\_role\_arn) | n/a |
| <a name="output_permission_boundary_policy_arn"></a> [permission\_boundary\_policy\_arn](#output\_permission\_boundary\_policy\_arn) | the name of the policy |
