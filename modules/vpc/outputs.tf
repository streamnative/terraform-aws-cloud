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

output "private_subnet_ids" {
  value       = aws_subnet.private.*.id
  description = "A list of private subnet ID's created by this module"
}

output "public_subnet_ids" {
  value       = aws_subnet.public.*.id
  description = "A list of public subnet ID's created by this module"
}

output "private_route_table_ids" {
  value = aws_route_table.private_route_table.*.id
}

output "public_route_table_ids" {
  value = [aws_route_table.public_route_table.id]
}

output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "The ID of the VPC created by this module"
}
