# eks-vpc-tags
This module adds the resource tags necessary for allowing Kubernetes ingress controllers to automatically discover available AWS subnets.

Just pass in the VPC ID, a list of private or public subnets, and the name of your EKS and the module will create the necessary tags.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ec2_tag.cluster_subnet_tag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.private_subnet_tag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.public_subnet_tag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.vpc_tag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of your EKS cluster and associated resources. Must be 16 characters or less | `string` | `""` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | The ids of existing private subnets | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | The ids of existing public subnets | `list(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the AWS VPC to use | `string` | `""` | no |

## Outputs

No outputs.
