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

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs     = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names
  num_azs = length(var.availability_zones) > 0 ? length(var.availability_zones) : var.num_azs
  tags    = merge(var.tags, var.additional_tags)
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge({ "Vendor" = "StreamNative", Name = format("%s-vpc", var.vpc_name) }, local.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "public" {
  count = local.num_azs

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.public_subnet_newbits, var.public_subnet_start + count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = var.disable_nat_gateway ? true : var.public_subnet_auto_ip
  tags                    = merge({ "Vendor" = "StreamNative", "Type" = "public", Name = format("%s-public-sbn-%s", var.vpc_name, count.index) }, local.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "private" {
  count = local.num_azs

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.private_subnet_newbits, var.private_subnet_start + count.index)
  availability_zone = local.azs[count.index]
  tags              = merge({ "Vendor" = "StreamNative", "Type" = "private", Name = format("%s-private-sbn-%s", var.vpc_name, count.index) }, local.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge({ "Vendor" = "StreamNative", Name = format("%s-igw", var.vpc_name) }, local.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_eip" "eip" {
  count = var.disable_nat_gateway ? 0 : local.num_azs

  domain = "vpc"
  tags   = merge({ "Vendor" = "StreamNative", Name = format("%s-eip-%s", var.vpc_name, count.index) }, local.tags)

  depends_on = [aws_internet_gateway.gw]
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count = var.disable_nat_gateway ? 0 : local.num_azs

  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge({ "Vendor" = "StreamNative", Name = format("%s-ngw-%s", var.vpc_name, count.index) }, local.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route_table" "public_route_table" {
  count = 1

  vpc_id = aws_vpc.vpc.id
  tags   = merge({ "Vendor" = "StreamNative", "Type" = "public", Name = format("%s-public-rtb", var.vpc_name) }, local.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route" "public_route" {
  count = 1

  route_table_id         = aws_route_table.public_route_table[0].id
  gateway_id             = aws_internet_gateway.gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_assoc" {
  count = local.num_azs

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table[0].id
}

resource "aws_route_table" "private_route_table" {
  count = var.disable_nat_gateway ? 0 : local.num_azs

  vpc_id = aws_vpc.vpc.id
  tags   = merge({ "Vendor" = "StreamNative", "Type" = "private", Name = format("%s-private-rtb-%s", var.vpc_name, count.index) }, local.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route" "private_route" {
  count = var.disable_nat_gateway ? 0 : local.num_azs

  route_table_id         = aws_route_table.private_route_table[count.index].id
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_assoc" {
  count = var.disable_nat_gateway ? 0 : local.num_azs

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

resource "aws_vpc_endpoint" "s3_gateway_endpoint" {
  count = var.disable_nat_gateway || !var.enable_s3_gateway_endpoint ? 0 : 1

  vpc_id            = aws_vpc.vpc.id
  service_name      = format("com.amazonaws.%s.s3", var.region)
  route_table_ids   = aws_route_table.private_route_table[*].id
  vpc_endpoint_type = "Gateway"

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = merge({ "Vendor" = "StreamNative", Name = "${var.vpc_name}-s3-gateway-endpoint" }, local.tags)
}

# S3 Tables traffic (s3tables.<region>.amazonaws.com) is not routed through
# the S3 gateway endpoint above. AWS publishes the s3tables service as an
# Interface VPC endpoint only, so provision one in the private subnets and
# enable private DNS to keep the traffic on the AWS private network. Set
# `enable_s3tables_endpoint = false` in regions where S3 Tables is not yet
# available (terraform apply will otherwise fail with InvalidServiceName).
resource "aws_security_group" "s3tables_endpoint" {
  count = var.enable_s3tables_endpoint ? 1 : 0

  name        = "${var.vpc_name}-s3tables-endpoint"
  description = "Allow HTTPS to the S3 Tables VPC interface endpoint"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  tags = merge({ "Vendor" = "StreamNative", Name = "${var.vpc_name}-s3tables-endpoint-sg" }, local.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_endpoint" "s3tables_endpoint" {
  count = var.enable_s3tables_endpoint ? 1 : 0

  vpc_id              = aws_vpc.vpc.id
  service_name        = format("com.amazonaws.%s.s3tables", var.region)
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.s3tables_endpoint[0].id]
  private_dns_enabled = true

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
POLICY

  tags = merge({ "Vendor" = "StreamNative", Name = "${var.vpc_name}-s3tables-endpoint" }, local.tags)
}