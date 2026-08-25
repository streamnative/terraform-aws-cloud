# Copyright 2023 StreamNative, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "name" {
  description = "The identifier used for the instance, its DB subnet group and its security group"
  type        = string
}

variable "vpc_id" {
  description = "The VPC the instance is placed in"
  type        = string
}

variable "vpc_cidr" {
  description = "The cidr block allowed to reach the instance. Must be the cidr actually in use by vpc_id, not a requested one."
  type        = string
}

variable "private_subnet_ids" {
  description = "The private subnets used by the DB subnet group"
  type        = list(string)
}

variable "database_name" {
  description = "The database created when the instance is provisioned"
  type        = string
  default     = "postgres"
}

variable "master_username" {
  description = "The root user created when the instance is provisioned"
  type        = string
  default     = "postgres"
}

variable "port" {
  description = "The port the instance listens on"
  type        = number
  default     = 5432
}

variable "engine_version" {
  description = "The PostgreSQL engine version. A major-only prefix tracks the latest minor."
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "The RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GiB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper bound for storage autoscaling in GiB. Set to 0 to disable autoscaling."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Deploy the instance across availability zones"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Days of automated backups to retain. 0 disables backups and point-in-time recovery."
  type        = number
  default     = 0
}

variable "additional_tags" {
  description = "Additional tags to apply to the resources"
  type        = map(string)
  default     = {}
}
