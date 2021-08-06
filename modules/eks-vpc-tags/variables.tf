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

variable "cluster_name" {
  default     = ""
  description = "The name of your EKS cluster and associated resources. Must be 16 characters or less"
  type        = string

  validation {
    condition     = can(length(var.cluster_name) <= 16)
    error_message = "The value for variable \"cluster_name\" must be a string of 16 characters or less."
  }
}

variable "private_subnet_ids" {
  default     = []
  description = "The ids of existing private subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids[0]) > 7 && substr(var.private_subnet_ids[0], 0, 7) == "subnet-"
    error_message = "The value for variable \"private_subnet_ids\" must be a valid subnet id, starting with \"subnet-\"."
  }
}

variable "public_subnet_ids" {
  default     = []
  description = "The ids of existing public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids[0]) > 7 && substr(var.public_subnet_ids[0], 0, 7) == "subnet-"
    error_message = "The value for variable \"public_subnet_ids\" must be a valid subnet id, starting with \"subnet-\"."
  }
}

variable "vpc_id" {
  default     = ""
  description = "The ID of the AWS VPC to use"
  type        = string

  validation {
    condition     = length(var.vpc_id) > 4 && substr(var.vpc_id, 0, 4) == "vpc-"
    error_message = "The value for variable \"vpc_id\" must be a valid VPC id, starting with \"vpc-\"."
  }
}