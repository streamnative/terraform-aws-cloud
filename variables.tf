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

variable "add_vpc_tags" {
  default     = false
  description = "Indicate whether the eks tags should be added to vpc and subnets"
  type        = bool
}

variable "aws_partition" {
  default     = "aws"
  description = "AWS partition: 'aws', 'aws-cn', or 'aws-us-gov'"
  type        = string
}

variable "cert_manager_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values"
  type        = map(any)
}

variable "cluster_autoscaler_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://hub.helm.sh/charts/bitnami/external-dns"
  type        = map(any)
}

variable "cluster_enabled_log_types" {
  default     = []
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
}

variable "cluster_name" {
  default     = ""
  description = "The name of your EKS cluster and associated resources. Must be 16 characters or less"
  type        = string

  validation {
    condition     = can(length(var.cluster_name) <= 16)
    error_message = "The value for variable \"cluster_name\" must be a string of 16 characters or less."
  }
}

variable "cluster_subnet_ids" {
  default     = []
  description = "A list of subnet IDs to place the EKS cluster and workers within"
  type        = list(string)
}

variable "cluster_version" {
  default     = "1.18"
  description = "The version of Kubernetes to be installed"
  type        = string
}

variable "csi_namespace" {
  default     = "kube-system"
  description = "The namespace used for AWS EKS Container Storage Interface (CSI)"
  type        = string
}

variable "csi_sa_name" {
  default     = "efs-csi-controller-sa"
  description = "The service account name used for AWS EKS Container Storage Interface (CSI)"
}

variable "disable_olm" {
  default     = true
  description = "Enables Operator Lifecycle Manager (OLM) on the EKS cluster, and disables installing operators via helm releases. This is currently disabled by default."
  type        = bool
}

variable "enable_irsa" {
  default     = true
  description = "Enables the OpenID Connect Provider for EKS to use IAM Roles for Service Accounts (IRSA)"
  type        = bool
}

variable "enable_function_mesh_operator" {
  default     = true
  description = "Enables the StreamNative Function Mesh Operator on the EKS cluster. Enabled by default, but disabled if var.disable_olm is set to `true`"
  type        = bool
}

variable "enable_prometheus_operator" {
  default     = true
  description = "Enables the Prometheus operator on the EKS cluster. Enabled by default, but disabled if var.disable_olm is set to `true`"
  type        = bool
}

variable "enable_pulsar_operator" {
  default     = true
  description = "Enables the Pulsar Operator on the EKS cluster. Enabled by default, but disabled if var.disable_olm is set to `true`"
  type        = bool
}

variable "enable_vault" {
  default     = true
  description = "Enables Hashicorp Vault on the EKS cluster."
  type        = bool
}

variable "external_dns_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://hub.helm.sh/charts/bitnami/external-dns"
  type        = map(any)
}
variable "function_mesh_operator_chart_name" {
  default     = "function-mesh-operator"
  description = "The name of the Helm chart to install"
  type        = string
}

variable "function_mesh_operator_chart_repository" {
  default     = "https://charts.streamnative.io"
  description = "The repository containing the Helm chart to install"
  type        = string
}

variable "function_mesh_operator_chart_version" {
  default     = "0.1.7"
  description = "The version of the Helm chart to install"
  type        = string
}

variable "function_mesh_operator_cleanup_on_fail" {
  default     = true
  description = "Allow deletion of new resources created in this upgrade when upgrade fails"
  type        = bool
}

variable "function_mesh_operator_release_name" {
  default     = "function-mesh-operator"
  description = "The name of the helm release"
  type        = string
}

variable "function_mesh_operator_settings" {
  default     = null
  description = "Additional settings which will be passed to the Helm chart values"
  type        = map(any)
}

variable "function_mesh_operator_timeout" {
  default     = 600
  description = "Time in seconds to wait for any individual kubernetes operation"
  type        = number
}

variable "func_pool_allowed_role_arns" {
  default = [
    "arn:aws:iam::*:role/pulsar-func-*"
  ]
  description = "The role resources (or patterns) that function roles can assume"
  type        = list(string)
}

variable "func_pool_desired_size" {
  type        = number
  default     = 1
  description = "Desired number of worker nodes"
}

variable "func_pool_disk_size" {
  default     = 20
  description = "Disk size in GiB for function worker nodes. Defaults to 20. Terraform will only perform drift detection if a configuration value is provided"
  type        = number
}

variable "func_pool_enabled" {
  default     = false
  description = "Enable an additional dedicated function pool"
  type        = bool
}

variable "func_pool_instance_types" {
  default     = ["t3.medium"]
  description = "Set of instance types associated with the EKS Node Group. Defaults to [\"t3.medium\"]. Terraform will only perform drift detection if a configuration value is provided"
  type        = list(string)
}

variable "func_pool_kubernetes_labels" {
  description = "Key-value mapping of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed"
  default     = {}
  type        = map(string)
}

variable "func_pool_min_size" {
  default     = 1
  description = "The minimum size of the AutoScaling Group"
  type        = number
}

variable "func_pool_max_size" {
  default     = 5
  description = "The maximum size of the AutoScaling Group"
  type        = number
}

variable "func_pool_namespace" {
  default     = "pulsar-funcs"
  description = "The namespace where functions run"
  type        = string
}

variable "func_pool_sa_name" {
  default     = "default"
  description = "The service account name the functions use"
  type        = string
}

variable "hosted_zone_id" {
  default     = ""
  description = "The ID of the Route53 hosted zone used by the cluster's external-dns configuration"
  type        = string
}

variable "kubeconfig_output_path" {
  default     = "./"
  description = "Where to save the Kubectl config file (if `write_kubeconfig = true`). Assumed to be a directory if the value ends with a forward slash `/`."
  type        = string
}

variable "manage_cluster_iam_resources" {
  default     = true
  description = "Whether to let the module manage worker IAM reosurces. If set to false, cluster_iam_role_name must be specified for workers"
  type        = bool
}

variable "manage_worker_iam_resources" {
  default     = false
  description = "Whether to let the module manage worker IAM reosurces. If set to false, cluster_iam_role_name must be specified for workers"
  type        = bool
}

variable "map_additional_aws_accounts" {
  default     = []
  description = "Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap"
  type        = list(string)
}

variable "map_additional_iam_roles" {
  default     = []
  description = "Additional IAM roles to add to `config-map-aws-auth` ConfigMap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

variable "map_additional_iam_users" {
  default     = []
  description = "Additional IAM roles to add to `config-map-aws-auth` ConfigMap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
}

variable "node_pool_desired_size" {
  description = "Desired number of worker nodes in the node pool"
  type        = number
}

variable "node_pool_disk_size" {
  default     = null
  description = "Disk size in GiB for worker nodes in the node pool. Defaults to 20. Terraform will only perform drift detection if a configuration value is provided"
  type        = number
}

variable "node_pool_instance_types" {
  default     = ["t3.medium"]
  description = "Set of instance types associated with the EKS Node Group. Defaults to [\"t3.medium\"]. Terraform will only perform drift detection if a configuration value is provided"
  type        = list(string)
}

variable "node_pool_min_size" {
  description = "The minimum size of the node pool AutoScaling group"
  type        = number
}

variable "node_pool_max_size" {
  description = "The maximum size of the node pool Autoscaling group"
  type        = number
}

variable "olm_namespace" {
  default     = "olm"
  description = "The namespace used by OLM and its resources"
  type        = string
}

variable "olm_operators_namespace" {
  default     = "operators"
  description = "The namespace where OLM will install the operators"
  type        = string
}

variable "olm_settings" {
  default     = null
  description = "Additional settings which will be passed to the Helm chart values"
  type        = map(any)
}

variable "olm_subscription_settings" {
  default     = null
  description = "Additional settings which will be passed to the Helm chart values"
  type        = map(any)
}

variable "private_subnet_ids" {
  default     = []
  description = "The ids of existing private subnets"
  type        = list(string)
}

variable "prometheus_operator_chart_name" {
  default     = "kube-prometheus-stack"
  description = "The name of the Helm chart to install"
  type        = string
}

variable "prometheus_operator_chart_repository" {
  default     = "https://prometheus-community.github.io/helm-charts"
  description = "The repository containing the Helm chart to install"
  type        = string
}

variable "prometheus_operator_chart_version" {
  default     = "16.12.1"
  description = "The version of the Helm chart to install"
  type        = string
}

variable "prometheus_operator_cleanup_on_fail" {
  default     = true
  description = "Allow deletion of new resources created in this upgrade when upgrade fails"
  type        = bool
}

variable "prometheus_operator_release_name" {
  default     = "kube-prometheus-stack"
  description = "The name of the helm release"
  type        = string
}
variable "prometheus_operator_settings" {
  default     = null
  description = "Additional settings which will be passed to the Helm chart values"
  type        = map(any)
}

variable "prometheus_operator_timeout" {
  default     = 600
  description = "Time in seconds to wait for any individual kubernetes operation"
  type        = number
}
variable "public_subnet_ids" {
  default     = []
  description = "The ids of existing public subnets"
  type        = list(string)
}

variable "pulsar_namespace" {
  type        = string
  description = "The Kubernetes namespace used for the Pulsar workload"
}

variable "pulsar_operator_chart_name" {
  default     = "pulsar-operator"
  description = "The name of the Helm chart to install"
  type        = string
}

variable "pulsar_operator_chart_repository" {
  default     = "https://charts.streamnative.io"
  description = "The repository containing the Helm chart to install"
  type        = string
}

variable "pulsar_operator_chart_version" {
  default     = "0.7.2"
  description = "The version of the Helm chart to install"
  type        = string
}

variable "pulsar_operator_cleanup_on_fail" {
  default     = true
  description = "Allow deletion of new resources created in this upgrade when upgrade fails"
  type        = bool
}

variable "pulsar_operator_release_name" {
  default     = "pulsar-operator"
  description = "The name of the helm release"
  type        = string
}

variable "pulsar_operator_settings" {
  default     = null
  description = "Additional settings which will be passed to the Helm chart values"
  type        = map(any)
}

variable "pulsar_operator_timeout" {
  default     = 600
  description = "Time in seconds to wait for any individual kubernetes operation"
  type        = number
}

variable "region" {
  default     = null
  description = "The AWS region"
  type        = string
}

variable "s3_bucket_name_override" {
  default     = ""
  description = "Overrides the name for S3 bucket resources"
  type        = string
}

variable "vault_operator_chart_name" {
  default     = "vault-operator"
  description = "The name of the Helm chart to install"
  type        = string
}

variable "vault_operator_chart_repository" {
  default     = "https://kubernetes-charts.banzaicloud.com"
  description = "The repository containing the Helm chart to install"
  type        = string
}

variable "vault_operator_chart_version" {
  default     = "1.13.0"
  description = "The version of the Helm chart to install"
  type        = string
}

variable "vault_operator_cleanup_on_fail" {
  default     = true
  description = "Allow deletion of new resources created in this upgrade when upgrade fails"
  type        = bool
}

variable "vault_operator_release_name" {
  default     = "vault-operator"
  description = "The name of the helm release"
  type        = string
}

variable "vault_operator_settings" {
  default     = null
  description = "Additional settings which will be passed to the Helm chart values"
  type        = map(any)
}

variable "vault_operator_timeout" {
  default     = 600
  description = "Time in seconds to wait for any individual kubernetes operation"
  type        = number
}

variable "vault_prefix_override" {
  default     = ""
  description = "Overrides the name prefix for Vault resources"
  type        = string
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

variable "wait_for_cluster_timeout" {
  default     = 0
  description = "Time in seconds to wait for the newly provisioned EKS cluster's API/healthcheck endpoint to return healthy, before applying the aws-auth configmap. Defaults to 300 seconds in the parent module \"terraform-aws-modules/eks/aws\", which is often too short. Increase to at least 900 seconds, if needed. See also https://github.com/terraform-aws-modules/terraform-aws-eks/pull/1420"
  type        = number
}

variable "write_kubeconfig" {
  default     = true
  description = "Whether to write a Kubectl config file containing the cluster configuration. Saved to variable \"kubeconfig_output_path\"."
  type        = bool
}
