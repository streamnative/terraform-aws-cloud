#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = format("%s-vpc", var.vpc_name) }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "public" {
  count                   = var.num_azs
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, var.public_subnet_start + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = var.public_subnet_auto_ip
  tags                    = { "type" = "public", Name = format("%s-public-sbn-%s", var.vpc_name, count.index) }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "private" {
  count             = var.num_azs
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, var.private_subnet_start + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { "type" = "private", Name = format("%s-private-sbn-%s", var.vpc_name, count.index) }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = format("%s-igw", var.vpc_name) }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_eip" "eip" {
  count = var.num_azs
  vpc   = true
}

resource "aws_nat_gateway" "nat_gw" {
  count         = var.num_azs
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = { Name = format("%s-ngw-%s", var.vpc_name, count.index) }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route_table" "public_route_table" {
  count  = var.num_azs
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = format("%s-public-rtb-%s", var.vpc_name, count.index) }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route" "public_route" {
  count                  = var.num_azs
  route_table_id         = aws_route_table.public_route_table[count.index].id
  gateway_id             = aws_internet_gateway.gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_assoc" {
  count          = var.num_azs
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table[count.index].id
}

resource "aws_route_table" "private_route_table" {
  count  = var.num_azs
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = format("%s-private-rtb-%s", var.vpc_name, count.index) }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route" "private_route" {
  count                  = var.num_azs
  route_table_id         = aws_route_table.private_route_table[count.index].id
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_assoc" {
  count          = var.num_azs
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}
