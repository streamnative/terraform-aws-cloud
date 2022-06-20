# StreamNative Managed Cloud
This Terraform module creates the resources necessary for StreamNative's vendor access into your AWS environment.

There are three main resources it creates, and one that is optional:

- [Permission Boundary Policy](https://github.com/streamnative/terraform-aws-cloud/blob/master/modules/managed-cloud/files/permission_boundary_iam_policy.json.tpl): This permission boundary defines the scope of exactly what is possible for StreamNative to do within your AWS account. It is self enforcing with strict requirements, to ensure that points of vulnerability (such as privledge escalation) are locked down and not possible. 

- Management role: This AWS IAM role is used for the day to day management of resources strictly owned by StreamNative. It is limited in its ability to create, modify, and delete resources within AWS.

- Bootstrap role (temporary/optional): This AWS IAM role is typically only needed for initial provisioning or deprovisioning. It has the ability to create and delete (within the limits of the permission boundary) EC2, EKS, IAM, DynamoDB, Route53, and KMS resources.

And optionally:

- Runtime policy: This policy is used by add-ons running in EKS that require an [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) for interacting with AWS services, such as `aws-load-balanacer-controller`, AWS `csi` storage driver,`external-dns`, `external-secrets`, `certificate-manager`, and `cluster-autoscaler`. This policy contains all the actions needed by these services, eliminating the need for `iam:CreatePolicy` as part of the Bootstrap function where it otherwise creates an IAM policy for each service. (at some point, this will become the default behavior)
## Usage

The module requires only one input to function:

- `region`: The AWS region where your StreamNative Managed environment is running (this is needed to restrict access to manage certain AWS resources to a particular region)

And if you are using the Runtime policy:

- `use_runtime_policy`: Enables the creation of the runtime policy for EKS addon services, allowing for a tighter set of restrictions for the Bootstrap role.

Assuming you are authenticated and authorized to the correct AWS environment, create a `main.tf` file containing the following:

```hcl
module "sn_managed_cloud" {
  source  = "streamnative/cloud/aws//modules/managed-cloud"
  
  region             = <YOUR_REGION>
  use_runtime_policy = true
}
```

And then run `terraform init && terraform apply` accordingly. 

When you are finished, the module will output the ARNs for the resources created by this module. Please provide these ARNs to your StreamNative Engineer when you are ready for us to begin creating your environment.

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
| <a name="provider_local"></a> [local](#provider\_local) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.alb_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.bootstrap_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.management_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.runtime_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.bootstrap_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.management_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.bootstrap_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.management_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [local_file.alb_policy](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.bootstrap_policy](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.management_policy](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.permission_boundary_policy](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.runtime_policy](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ebs_default_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |
| [aws_iam_policy_document.runtime_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.streamnative_control_plane_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.streamnative_vendor_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.default_ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_bootstrap_role"></a> [create\_bootstrap\_role](#input\_create\_bootstrap\_role) | Whether or not to create the bootstrap role, which is used by StreamNative for the initial deployment of the StreamNative Cloud | `string` | `true` | no |
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | The external ID, provided by StreamNative, which is used for all assume role calls. If not provided, no check for external\_id is added. (NOTE: a future version will force the passing of this parameter) | `string` | `""` | no |
| <a name="input_partition"></a> [partition](#input\_partition) | AWS partition: 'aws', 'aws-cn', or 'aws-us-gov', used when constructing IRSA trust relationship policies. | `string` | `"aws"` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region where your instance of StreamNative Cloud is deployed. Defaults to all regions "*" | `string` | `"*"` | no |
| <a name="input_runtime_ebs_kms_key_arns"></a> [runtime\_ebs\_kms\_key\_arns](#input\_runtime\_ebs\_kms\_key\_arns) | when using runtime policy, sets the list of allowed kms key arns, if not set, uses the default ebs kms key | `list(any)` | `[]` | no |
| <a name="input_runtime_eks_cluster_pattern"></a> [runtime\_eks\_cluster\_pattern](#input\_runtime\_eks\_cluster\_pattern) | when using runtime policy, defines the eks clsuter prefix for streamnative clusters | `string` | `"aws*snc"` | no |
| <a name="input_runtime_eks_nodepool_pattern"></a> [runtime\_eks\_nodepool\_pattern](#input\_runtime\_eks\_nodepool\_pattern) | when using runtime policy, defines the bucket prefix for streamnative managed buckets (backup and offload) | `string` | `"snc-*-pool*"` | no |
| <a name="input_runtime_enable_secretsmanager"></a> [runtime\_enable\_secretsmanager](#input\_runtime\_enable\_secretsmanager) | when using runtime policy, allows for secretsmanager access | `bool` | `false` | no |
| <a name="input_runtime_hosted_zone_allowed_ids"></a> [runtime\_hosted\_zone\_allowed\_ids](#input\_runtime\_hosted\_zone\_allowed\_ids) | when using runtime policy, allows for further scoping down policy for allowed hosted zones | `list(any)` | <pre>[<br>  "*"<br>]</pre> | no |
| <a name="input_runtime_s3_bucket_pattern"></a> [runtime\_s3\_bucket\_pattern](#input\_runtime\_s3\_bucket\_pattern) | when using runtime policy, defines the bucket prefix for streamnative managed buckets (backup and offload) | `string` | `"snc-*"` | no |
| <a name="input_runtime_vpc_allowed_ids"></a> [runtime\_vpc\_allowed\_ids](#input\_runtime\_vpc\_allowed\_ids) | when using runtime policy, allows for further scoping down policy for allowed VPC | `list(any)` | <pre>[<br>  "*"<br>]</pre> | no |
| <a name="input_sn_policy_version"></a> [sn\_policy\_version](#input\_sn\_policy\_version) | The value of SNVersion tag | `string` | `"2.0"` | no |
| <a name="input_source_identities"></a> [source\_identities](#input\_source\_identities) | Place an additional constraint on source identity, disabled by default and only to be used if specified by StreamNative | `list(any)` | `[]` | no |
| <a name="input_source_identity_test"></a> [source\_identity\_test](#input\_source\_identity\_test) | The test to use for source identity | `string` | `"ForAnyValue:StringLike"` | no |
| <a name="input_streamnative_control_plane_role_arn"></a> [streamnative\_control\_plane\_role\_arn](#input\_streamnative\_control\_plane\_role\_arn) | The ARN of the role that is used by StreamNative for Control Plane operations | `string` | `"arn:aws:iam::311022431024:role/cloud-manager"` | no |
| <a name="input_streamnative_control_plane_user_arn"></a> [streamnative\_control\_plane\_user\_arn](#input\_streamnative\_control\_plane\_user\_arn) | The ARN of the user that is used by StreamNative for Control Plane operations with generic authentication method | `string` | `"arn:aws-cn:iam::146097325273:user/aws-cn-test"` | no |
| <a name="input_streamnative_google_account_id"></a> [streamnative\_google\_account\_id](#input\_streamnative\_google\_account\_id) | The Google Cloud service account ID used by StreamNative for Control Plane operations | `string` | `"108050666045451143798"` | no |
| <a name="input_streamnative_vendor_access_role_arn"></a> [streamnative\_vendor\_access\_role\_arn](#input\_streamnative\_vendor\_access\_role\_arn) | The arn for the IAM principle (role) provided by StreamNative. This role is used exclusively by StreamNative (with strict permissions) for vendor access into your AWS account | `string` | `"arn:aws:iam::311022431024:role/cloud-manager"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags to apply to the resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_use_runtime_policy"></a> [use\_runtime\_policy](#input\_use\_runtime\_policy) | instead of relying on permission boundary use static runtime policies | `bool` | `false` | no |
| <a name="input_write_policy_files"></a> [write\_policy\_files](#input\_write\_policy\_files) | Write the policy files locally to disk for debugging and validation | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_lbc_policy_arn"></a> [aws\_lbc\_policy\_arn](#output\_aws\_lbc\_policy\_arn) | The ARN of the AWS Load Balancer Controller Policy, if enabled |
| <a name="output_bootstrap_role_arn"></a> [bootstrap\_role\_arn](#output\_bootstrap\_role\_arn) | The ARN of the Bootstrap role, if enabled |
| <a name="output_management_role_arn"></a> [management\_role\_arn](#output\_management\_role\_arn) | The ARN of the Management Role |
| <a name="output_permission_boundary_policy_arn"></a> [permission\_boundary\_policy\_arn](#output\_permission\_boundary\_policy\_arn) | The ARN of the Permssion Boundary Policy |
| <a name="output_runtime_policy_arn"></a> [runtime\_policy\_arn](#output\_runtime\_policy\_arn) | The ARN of the Runtime Policy, if enabled |
