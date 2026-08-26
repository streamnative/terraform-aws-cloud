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

# RDS Module
Creates a private PostgreSQL instance in the cluster VPC's private subnets, together with its DB subnet group, security group and generated master password. The instance is never publicly accessible and is reachable only from within the VPC on the configured port.

The instance is treated as disposable: automated backups default to off, no snapshot is taken on delete, and deletion protection is off so teardown cannot be blocked.

The module deliberately has no Kubernetes provider. It returns a sensitive `connection` object so the caller can write the credential to whatever secret store it uses.

### Note on `vpc_cidr`
`vpc_cidr` must be the cidr **actually in use** by `vpc_id`, not a requested or default value. When the VPC is supplied rather than created, read it with a `data "aws_vpc"` lookup — passing the requested cidr produces an ingress rule that does not match the VPC and the instance becomes unreachable.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.61.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_ingress_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [random_password.master](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to apply to the resources | `map(string)` | `{}` | no |
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | Initial storage in GiB | `number` | `20` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Days of automated backups to retain. 0 disables backups and point-in-time recovery. | `number` | `0` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The database created when the instance is provisioned | `string` | `"postgres"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The PostgreSQL engine version. A major-only prefix tracks the latest minor. | `string` | `"16"` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The RDS instance class | `string` | `"db.t4g.micro"` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | The root user created when the instance is provisioned | `string` | `"postgres"` | no |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | Upper bound for storage autoscaling in GiB. Set to 0 to disable autoscaling. | `number` | `100` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Deploy the instance across availability zones | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | The identifier used for the instance, its DB subnet group and its security group | `string` | n/a | yes |
| <a name="input_port"></a> [port](#input\_port) | The port the instance listens on | `number` | `5432` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | The private subnets used by the DB subnet group | `list(string)` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The cidr block allowed to reach the instance. Must be the cidr actually in use by vpc\_id, not a requested one. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC the instance is placed in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connection"></a> [connection](#output\_connection) | Connection details for the instance, including the master password |
| <a name="output_identifier"></a> [identifier](#output\_identifier) | The DB instance identifier |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The security group protecting the instance |
<!-- END_TF_DOCS -->
