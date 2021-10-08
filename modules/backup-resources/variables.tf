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

variable "aws_partition" {
  default     = "aws"
  description = "AWS partition: 'aws', 'aws-cn', or 'aws-us-gov'"
  type        = string
}

variable "cluster_name" {
  description = "The name of your EKS cluster and associated resources"
  type        = string
}

variable "oidc_issuer" {
  description = "The OIDC issuer for the EKS cluster"
  type        = string
}

variable "permissions_boundary_arn" {
  default     = null
  description = "If required, provide the ARN of the IAM permissions boundary to use for restricting StreamNative's vendor access"
  type        = string
}

variable "pulsar_namespace" {
  description = "The namespace where Pulsar is deployed. This is required in order for Velero to backup Pulsar"
  type        = string
}

variable "service_account_name" {
  default     = "velero"
  description = "The name of the kubernetes service account to used by Velero backups. Defaults to \"velero\". This is required to set the appropriate policy permissions for IRSA, which grants the Kubernetes Service Account access to use the IAM role"
  type        = string
}

variable "velero_backup_schedule" {
  default     = "0 5 * * *"
  description = "The scheduled time for Velero to perform backups. Written in cron expression, defaults to \"0 5 * * *\" or \"at 5:00am every day\""
  type        = string
}

variable "velero_excluded_namespaces" {
  default     = ["default", "kube-system", "operators", "olm"]
  description = "A comma-separated list of namespaces to exclude from Velero backups. "
  type        = list(string)
}

variable "velero_helm_chart_name" {
  default     = "velero"
  description = "The name of the Helm chart to use for Velero"
  type        = string
}

variable "velero_helm_chart_repository" {
  default     = "https://vmware-tanzu.github.io/helm-charts"
  description = "The repository containing the Helm chart to use for velero"
  type        = string
}

variable "velero_helm_chart_version" {
  default     = "2.23.12"
  description = "The version of the Helm chart to use for Velero The current version can be found in github: https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/Chart.yaml"
  type        = string
}

variable "velero_namespace" {
  default     = "sn-system"
  description = "The kubernetes namespace where Velero should be deployed. This is required to set the appropriate policy permissions for IRSA, which grants the Kubernetes Service Account access to use the IAM role. Defaults to \"sn-system\""
  type        = string
}

variable "velero_plugin_version" {
  default     = "v1.3.0"
  description = "Which version of the velero-plugin-for-aws to use. Defaults to v1.3.0"
  type        = string
}

variable "velero_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values for Velero. See https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero for available options"
  type        = map(string)
}

variable "tags" {
  default     = {}
  description = "Tags to be added to the bucket and corresponding resources"
  type        = map(string)
}
