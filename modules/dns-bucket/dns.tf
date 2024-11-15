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

locals {
  new_zone_name = "${var.pm_name}.${var.parent_zone_name}"
  zone_name     = var.custom_dns_zone_name != "" ? var.custom_dns_zone_name : try(aws_route53_zone.zone[0].name, "")
  zone_id       = var.custom_dns_zone_id != "" ? var.custom_dns_zone_id : try(aws_route53_zone.zone[0].id, "")
}

resource "aws_route53_zone" "zone" {
  count    = var.custom_dns_zone_id == "" ? 1 : 0
  provider = aws.target

  name          = local.new_zone_name
  tags          = local.tags
  force_destroy = true
}

data "aws_route53_zone" "sn" {
  count    = var.custom_dns_zone_id == "" ? 1 : 0
  provider = aws.source

  name = var.parent_zone_name
}

resource "aws_route53_record" "delegate" {
  count    = var.custom_dns_zone_id == "" ? 1 : 0
  provider = aws.source

  zone_id = data.aws_route53_zone.sn[0].zone_id
  name    = aws_route53_zone.zone[0].name
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.zone[0].name_servers
}
