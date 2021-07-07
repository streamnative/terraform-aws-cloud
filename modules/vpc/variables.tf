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

variable "num_azs" {
  type        = number
  description = "The number of availability zones to provision"
  default     = 2
}

variable "region" {
  type = string
  validation {
    condition     = can(regex("^(us|af|ap|ca|eu|me|sa)\\-(east|west|south|northeast|southeast|central|north)\\-(1|2|3)$", var.region))
    error_message = "The region must be a proper AWS region."
  }
}

variable "private_subnet_start" {
  type    = number
  default = 10
}

variable "public_subnet_start" {
  type    = number
  default = 20
}

variable "public_subnet_auto_ip" {
  type    = bool
  default = false
}

variable "vpc_cidr" {
  validation {
    condition     = can(regex("^10\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/16", var.vpc_cidr))
    error_message = "The vpc_cidr must be a 10.x.x.x range with /16 CIDR."
  }
}
