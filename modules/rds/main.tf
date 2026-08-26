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

# A private PostgreSQL instance in the cluster VPC's private subnets. It is never
# publicly accessible and is reachable only from within the VPC on var.port.
#
# The instance is treated as disposable: backups default to off, no snapshot is
# taken on delete, and deletion protection is off so teardown cannot be blocked.

locals {
  tags = merge({
    "Vendor" = "StreamNative"
    "Name"   = var.name
  }, var.additional_tags)
}

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.private_subnet_ids
  tags       = local.tags
}

resource "aws_security_group" "this" {
  name        = var.name
  description = format("PostgreSQL access from within the VPC for %s", var.name)
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  security_group_id = aws_security_group.this.id
  description       = "PostgreSQL from the VPC"
  cidr_ipv4         = var.vpc_cidr
  from_port         = var.port
  to_port           = var.port
  ip_protocol       = "tcp"
}

resource "random_password" "master" {
  length = 32
  # RDS rejects '/', '@', '"' and ' ' in master passwords, and the credential is
  # consumed as a connection string, so stay within alphanumerics
  special = false
}

resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = var.port

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period = var.backup_retention_period
  # stays on with the major-only engine_version above; the provider only supports
  # a version prefix when auto minor upgrades are enabled
  auto_minor_version_upgrade = true
  apply_immediately          = true
  copy_tags_to_snapshot      = true

  # never block teardown on a disposable store
  deletion_protection = false
  skip_final_snapshot = true

  tags = local.tags
}
