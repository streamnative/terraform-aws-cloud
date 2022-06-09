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

output "bootstrap_role_arn" {
  value       = join("", aws_iam_role.bootstrap_role.*.arn)
  description = "The ARN of the Bootstrap role, if enabled"
}

output "management_role_arn" {
  value       = aws_iam_role.management_role.arn
  description = "The ARN of the Management Role"
}

output "runtime_policy_arn" {
  value       = join("", aws_iam_policy.runtime_policy.*.arn)
  description = "The ARN of the Runtime Policy, if enabled"
}

output "aws_lbc_policy_arn" {
  value       = join("", aws_iam_policy.alb_policy.*.arn)
  description = "The ARN of the AWS Load Balancer Controller Policy, if enabled"
}

output "permission_boundary_policy_arn" {
  value       = aws_iam_policy.permission_boundary.arn
  description = "The ARN of the Permssion Boundary Policy"
}
