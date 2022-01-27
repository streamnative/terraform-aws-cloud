# StreamNative Managed Cloud
This Terraform module creates the resources necessary for StreamNative's vendor access into your AWS environment.

There are three main resources it creates:

- [Permission Boundary Policy](https://github.com/streamnative/terraform-aws-cloud/blob/master/modules/managed-cloud/files/permission_boundary_iam_policy.json.tpl): This permission boundary defines the scope of exactly what is possible for StreamNative to do within your AWS account. It is self enforcing with strict requirements, to ensure that points of vulnerability (such as privledge escalation) are locked down and not possible. 

- Management role: This AWS IAM role is used for the day to day management of resources strictly owned by StreamNative. It is limited in its ability to create, modify, and delete resources within AWS.

- Bootstrap role (temporary/optional): This AWS IAM role is typically only needed for initial provisioning or deprovisioning. It has the ability to create and delete (within the limits of the permission boundary) EC2, EKS, IAM, DynamoDB, Route53, and KMS resources.

## Usage

The module only requires two inputs:

- `region`: The AWS region where your StreamNative Managed environment is running (this is needed to restrict access to manage certain AWS resources to a particular region)
- `streamnative_vendor_access_role_arn`: The ARN for the support role given to you by StreamNative. This is specific to you as a customer, and is the identity we will use when assuming the designated IAM roles in your account. It has a trust relationship specific to the AWS account you've designated for StreamNative's access.

Assuming you are authenticated and authorized to the correct AWS environment, create a `main.tf` file containing the following:

```hcl
module "sn_managed_cloud" {
  source  = "streamnative/cloud/aws//modules/managed-cloud"
  
  region = <YOUR_REGION>
  streamnative_vendor_access_role_arn = <ARN_SUPPLIED_BY_STREAMNATIVE>
}
```

And then run `terraform init && terraform apply` accordingly. 

## CloudFormation (optional)
If you do not use Terraform or prefer a more AWS native approach to deploying these resources, the [`cloudformation`](https://github.com/streamnative/terraform-aws-cloud/tree/master/modules/managed-cloud/cloudformation) directory contains a stack template file you can use. It creates the same resources mentioned above, just upload the stack and provide the necessary `VendorSupportRoleArn` parameter.

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
| [aws_iam_policy.bootstrap_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.management_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.bootstrap_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.management_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.bootstrap_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.management_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.streamnative_control_plane_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.streamnative_vendor_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_bootstrap_role"></a> [create\_bootstrap\_role](#input\_create\_bootstrap\_role) | Whether or not to create the bootstrap role, which is used by StreamNative for the initial deployment of the StreamNative Cloud | `string` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region where your instance of StreamNative Cloud is deployed, i.e. "us-west-2" | `string` | n/a | yes |
| <a name="input_streamnative_control_plane_role_arn"></a> [streamnative\_control\_plane\_role\_arn](#input\_streamnative\_control\_plane\_role\_arn) | The ARN of the role that is used by StreamNative for Control Plane operations | `string` | `"arn:aws:iam::311022431024:role/cloud-manager"` | no |
| <a name="input_streamnative_google_account_id"></a> [streamnative\_google\_account\_id](#input\_streamnative\_google\_account\_id) | The Google Cloud service account ID used by StreamNative for Control Plane operations | `string` | `"108050666045451143798"` | no |
| <a name="input_streamnative_vendor_access_role_arn"></a> [streamnative\_vendor\_access\_role\_arn](#input\_streamnative\_vendor\_access\_role\_arn) | The arn for the IAM principle (role) provided by StreamNative. This role is used exclusively by StreamNative (with strict permissions) for vendor access into your AWS account | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags to apply to the resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bootstrap_role_arn"></a> [bootstrap\_role\_arn](#output\_bootstrap\_role\_arn) | the arn of the role |
| <a name="output_management_role_arn"></a> [management\_role\_arn](#output\_management\_role\_arn) | n/a |
| <a name="output_permission_boundary_policy_arn"></a> [permission\_boundary\_policy\_arn](#output\_permission\_boundary\_policy\_arn) | the name of the policy |
