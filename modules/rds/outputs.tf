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

# The whole object is sensitive because it carries the master password. Callers
# are expected to hand it straight to a secret store rather than log it.
output "connection" {
  description = "Connection details for the instance, including the master password"
  sensitive   = true
  value = {
    host     = aws_db_instance.this.address
    port     = tostring(aws_db_instance.this.port)
    username = aws_db_instance.this.username
    password = random_password.master.result
    database = aws_db_instance.this.db_name
  }
}

output "identifier" {
  description = "The DB instance identifier"
  value       = aws_db_instance.this.identifier
}

output "security_group_id" {
  description = "The security group protecting the instance"
  value       = aws_security_group.this.id
}
