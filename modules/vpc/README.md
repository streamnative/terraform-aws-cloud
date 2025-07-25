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

# VPC Module
A basic module used to create an AWS VPC with public and private subnets, intended to be used specifically by an EKS cluster that is publically addressable on the internet.

### Note on Tags

Adding a lifecycle `ignore_changes` block to resource tags in this module prevents cycling when managing them seperately via the Terraform `aws_ec2_tag` resource.

Per the `aws_ec2_tag` [resource documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag):

"..using `aws_vpc` and `aws_ec2_tag` to manage tags of the same VPC will cause a perpetual difference where the aws_vpc resource will try to remove the tag being added by the aws_ec2_tag resource."

In order for [subnet auto discovery](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/8db51cb82370fba5e25e470829520e1da219776f/docs/deploy/subnet_discovery.md) in EKS to work properly, certain VPC resources need to be tagged with values specific to the EKS cluster they are associated with. These tags are often applied _after_ cluster creation, creating circular dependencies if trying to manage them within the actual VPC resouce.

For this reason, we recommend managing the tags externally of the resource itself, and have thus added the `ignore_changes` block to any resource using a tag which makes the default tags applied by this module static, rather than being able to dynamically provide additional tags to this module.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.64.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.36.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.nat_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.s3_gateway_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | The availability zones to provision. If specified will ignore num\_azs | `list(string)` | `[]` | no |
| <a name="input_disable_nat_gateway"></a> [disable\_nat\_gateway](#input\_disable\_nat\_gateway) | If set to true, will not create NAT Gateway and EC2 Nodes should put in public subnets. This could be useful when wanna save costs from nat gateway. | `bool` | `false` | no |
| <a name="input_num_azs"></a> [num\_azs](#input\_num\_azs) | The number of availability zones to provision | `number` | `2` | no |
| <a name="input_private_subnet_newbits"></a> [private\_subnet\_newbits](#input\_private\_subnet\_newbits) | The number of bits to added to the VPC CIDR prefix. For instance, if your VPC CIDR is a /16 and you set this number to 4, the subnets will be /20s. | `number` | `4` | no |
| <a name="input_private_subnet_start"></a> [private\_subnet\_start](#input\_private\_subnet\_start) | The starting octet for the private subnet CIDR blocks generated by this module. | `number` | `0` | no |
| <a name="input_public_subnet_auto_ip"></a> [public\_subnet\_auto\_ip](#input\_public\_subnet\_auto\_ip) | n/a | `bool` | `false` | no |
| <a name="input_public_subnet_newbits"></a> [public\_subnet\_newbits](#input\_public\_subnet\_newbits) | The number of bits to added to the VPC CIDR prefix. For instance, if your VPC CIDR is a /16 and you set this number to 4, the subnets will be /20s. | `number` | `4` | no |
| <a name="input_public_subnet_start"></a> [public\_subnet\_start](#input\_public\_subnet\_start) | The starting octet for the public subnet CIDR blocks generated by this module. | `number` | `8` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional to apply to the resources. Note that this module sets the tags Name, Type, and Vendor by default. They can be overwritten, but it is not recommended. | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR range to be used by the AWS VPC. We recommend using a /16 prefix to automatically generate /20 subnets. If you are using a smaller or larger prefix, refer to the subnet\_newbits variable to ensure that the generated subnet ranges are a valid for EKS (minimum /20 is recommended). | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name used for the VPC and associated resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | n/a |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | A list of private subnet ID's created by this module |
| <a name="output_public_route_table_ids"></a> [public\_route\_table\_ids](#output\_public\_route\_table\_ids) | n/a |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | A list of public subnet ID's created by this module |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC created by this module |
<!-- END_TF_DOCS -->