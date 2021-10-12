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

variable "create_bootstrap_role" {
  default     = true
  description = "Whether or not to create the bootstrap role, which is used by StreamNative for the initial deployment of the StreamNative Cloud"
  type        = string

}

variable "region" {
  description = "The AWS region where your instance of StreamNative Cloud is deployed, i.e. \"us-west-2\""
  type        = string
}

variable "streamnative_vendor_access_role_arn" {
  description = "The arn for the IAM principle (role) provided by StreamNative. This role is used exclusively by StreamNative (with strict permissions) for vendor access into your AWS account"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Extra tags to apply to the resources created by this module."
  type        = map(string)
}