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

variable "additional_tags" {
  default     = {}
  description = "Additional tags to be added to the resources created by this module."
  type        = map(any)
}

variable "add_vpc_tags" {
  default     = true
  description = "Adds tags to VPC resources necessary for ingress resources within EKS to perform auto-discovery of subnets. Defaults to \"true\". Note that this may cause resource cycling (delete and recreate) if you are using Terraform to manage your VPC resources without having a `lifecycle { ignore_changes = [ tags ] }` block defined within them, since the VPC resources will want to manage the tags themselves and remove the ones added by this module."
  type        = bool
}

variable "allowed_public_cidrs" {
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks that are allowed to access the EKS cluster's public endpoint. Defaults to \"0.0.0.0/0\" (any)."
  type        = list(string)
}

variable "asm_secret_arns" {
  default     = []
  description = "The a list of ARNs for secrets stored in ASM. This grants the kubernetes-external-secrets controller select access to secrets used by resources within the EKS cluster. If no arns are provided via this input, the IAM policy will allow read access to all secrets created in the provided region."
  type        = list(string)
}

variable "aws_load_balancer_controller_helm_chart_name" {
  default     = "aws-load-balancer-controller"
  description = "The name of the Helm chart to use for the AWS Load Balancer Controller."
  type        = string
}

variable "aws_load_balancer_controller_helm_chart_repository" {
  default     = "https://aws.github.io/eks-charts"
  description = "The repository containing the Helm chart to use for the AWS Load Balancer Controller."
  type        = string
}

variable "aws_load_balancer_controller_helm_chart_version" {
  default     = "1.3.2"
  description = "The version of the Helm chart to use for the AWS Load Balancer Controller. The current version can be found in github: https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/Chart.yaml."
  type        = string
}

variable "aws_load_balancer_controller_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values for the AWS Load Balancer Controller. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller for available options."
  type        = map(string)
}

variable "aws_partition" {
  default     = "aws"
  description = "AWS partition: 'aws', 'aws-cn', or 'aws-us-gov', used when constructing IRSA trust relationship policies."
  type        = string
}

variable "calico_helm_chart_name" {
  default     = "tigera-operator"
  description = "The name of the Helm chart in the repository for Calico, which is installed alongside the tigera-operator."
  type        = string
}

variable "calico_helm_chart_repository" {
  default     = "https://stevehipwell.github.io/helm-charts/"
  description = "The repository containing the calico helm chart. We are currently using a community provided chart, which is a fork of the official chart published by Tigera. This chart isn't as opinionated about namespaces, and should be used until this issue is resolved https://github.com/projectcalico/calico/issues/4812."
  type        = string
}

variable "calico_helm_chart_version" {
  default     = "1.5.0"
  description = "Helm chart version for Calico. Defaults to \"1.0.5\". See https://github.com/stevehipwell/helm-charts/tree/master/charts/tigera-operator for available version releases."
  type        = string
}

variable "calico_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values. See https://github.com/stevehipwell/helm-charts/tree/master/charts/tigera-operator for available options."
  type        = map(any)
}

variable "cert_manager_helm_chart_name" {
  default     = "cert-manager"
  description = "The name of the Helm chart in the repository for cert-manager."
  type        = string
}

variable "cert_manager_helm_chart_repository" {
  default     = "https://charts.bitnami.com/bitnami"
  description = "The repository containing the cert-manager helm chart."
  type        = string
}

variable "cert_manager_helm_chart_version" {
  default     = "0.1.27"
  description = "Helm chart version for the cert-manager. See https://github.com/bitnami/charts/tree/master/bitnami/cert-manager for version releases."
  type        = string
}

variable "cert_manager_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values. See https://github.com/bitnami/charts/tree/master/bitnami/cert-manager for available options."
  type        = map(any)
}

variable "cert_issuer_support_email" {
  default     = "certs-support@streamnative.io"
  description = "The email address to receive notifications from the cert issuer."
  type        = string
}

variable "cluster_autoscaler_helm_chart_name" {
  default     = "cluster-autoscaler"
  description = "The name of the Helm chart in the repository for cluster-autoscaler."
  type        = string
}

variable "cluster_autoscaler_helm_chart_repository" {
  default     = "https://kubernetes.github.io/autoscaler"
  description = "The repository containing the cluster-autoscaler helm chart."
  type        = string
}

variable "cluster_autoscaler_helm_chart_version" {
  default     = "9.10.8"
  description = "Helm chart version for the cluster-autoscaler. Defaults to \"9.10.4\". See https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler for more details."
  type        = string
}

variable "cluster_autoscaler_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values for cluster-autoscaler, see https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler for options."
  type        = map(any)
}

variable "cluster_enabled_log_types" {
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  description = "A list of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)."
  type        = list(string)
}

variable "cluster_log_kms_key_id" {
  default     = ""
  description = "If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)."
  type        = string
}

variable "cluster_log_retention_in_days" {
  default     = 90
  description = "Number of days to retain log events. Default retention - 90 days."
  type        = number
}

variable "cluster_name" {
  default     = ""
  description = "The name of your EKS cluster and associated resources. Must be 16 characters or less."
  type        = string

  validation {
    condition     = can(length(var.cluster_name) <= 16)
    error_message = "The value for variable \"cluster_name\" must be a string of 16 characters or less."
  }
}

variable "cluster_version" {
  default     = "1.20"
  description = "The version of Kubernetes to be installed."
  type        = string
}

variable "csi_helm_chart_name" {
  default     = "aws-ebs-csi-driver"
  description = "The name of the Helm chart in the repository for CSI."
  type        = string
}

variable "csi_helm_chart_repository" {
  default     = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
  description = "The repository containing the CSI helm chart"
  type        = string
}

variable "csi_helm_chart_version" {
  default     = "2.4.1"
  description = "Helm chart version for CSI"
  type        = string
}

variable "csi_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/charts/aws-ebs-csi-driver/values.yaml for available options."
  type        = map(any)
}

variable "disk_encryption_kms_key_id" {
  default     = ""
  description = "The KMS Key ARN to use for disk encryption."
  type        = string
}

variable "enable_aws_load_balancer_controller" {
  default     = true
  description = "Whether to enable the AWS Load Balancer Controller addon on the cluster. Defaults to \"true\", and in most situations is required by StreamNative Cloud."
  type        = bool
}

variable "enable_calico" {
  default     = false
  description = "Enables the Calico networking service on the cluster. Defaults to \"false\"."
  type        = bool
}

variable "enable_cert_manager" {
  default     = true
  description = "Enables the Cert-Manager addon service on the cluster. Defaults to \"true\", and in most situations is required by StreamNative Cloud."
  type        = bool
}

variable "enable_cluster_autoscaler" {
  default     = true
  description = "Enables the Cluster Autoscaler addon service on the cluster. Defaults to \"true\", and in most situations is recommened for StreamNative Cloud."
  type        = bool
}

variable "enable_csi" {
  default     = true
  description = "Enables the EBS Container Storage Interface (CSI) driver on the cluster, which allows for EKS manage the lifecycle of persistant volumes in EBS."
  type        = bool
}
variable "enable_external_secrets" {
  default     = false
  description = "Enables kubernetes-external-secrets addon service on the cluster. Defaults to \"false\""
  type        = bool
}

variable "enable_external_dns" {
  default     = true
  description = "Enables the External DNS addon service on the cluster. Defaults to \"true\", and in most situations is required by StreamNative Cloud."
}

variable "enable_func_pool" {
  default     = true
  description = "Enable an additional dedicated function pool."
  type        = bool
}

variable "enable_istio" {
  default     = true
  description = "Enables Istio on the cluster. Set to \"true\" by default."
  type        = bool
}

variable "enable_node_group_private_networking" {
  default     = true
  description = "Enables private networking for the EKS node groups (not the EKS cluster endpoint, which remains public), meaning Kubernetes API requests that originate within the cluster's VPC use a private VPC endpoint for EKS. Defaults to \"true\"."
  type        = bool
}

variable "external_dns_helm_chart_name" {
  default     = "external-dns"
  description = "The name of the Helm chart in the repository for ExternalDNS."
  type        = string
}

variable "external_dns_helm_chart_repository" {
  default     = "https://charts.bitnami.com/bitnami"
  description = "The repository containing the ExternalDNS helm chart."
  type        = string
}

variable "external_dns_helm_chart_version" {
  default     = "5.5.2"
  description = "Helm chart version for ExternalDNS. Defaults to \"4.9.0\". See https://hub.helm.sh/charts/bitnami/external-dns for updates."
  type        = string
}

variable "external_dns_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://hub.helm.sh/charts/bitnami/external-dns."
  type        = map(any)
}

variable "external_secrets_helm_chart_name" {
  default     = "kubernetes-external-secrets"
  description = "The name of the Helm chart in the repository for kubernetes-external-secrets."
  type        = string
}

variable "external_secrets_helm_chart_repository" {
  default     = "https://external-secrets.github.io/kubernetes-external-secrets"
  description = "The repository containing the kubernetes-external-secrets helm chart."
  type        = string
}

variable "external_secrets_helm_chart_version" {
  default     = "8.3.0"
  description = "Helm chart version for kubernetes-external-secrets. Defaults to \"8.3.0\". See https://github.com/external-secrets/kubernetes-external-secrets/tree/master/charts/kubernetes-external-secrets for updates."
  type        = string
}

variable "external_secrets_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://github.com/external-secrets/kubernetes-external-secrets/tree/master/charts/kubernetes-external-secrets for available options."
  type        = map(any)
}

variable "func_pool_desired_size" {
  type        = number
  default     = 0
  description = "Desired number of worker nodes"
}

variable "func_pool_disk_size" {
  default     = 50
  description = "Disk size in GiB for function worker nodes. Defaults to 20. Terraform will only perform drift detection if a configuration value is provided."
  type        = number
}

variable "func_pool_disk_type" {
  default     = "gp3"
  description = "Disk type for function worker nodes. Defaults to gp3."
  type        = string
}

variable "func_pool_instance_types" {
  default     = ["c6i.large"]
  description = "Set of instance types associated with the EKS Node Group. Defaults to [\"t3.large\"]. Terraform will only perform drift detection if a configuration value is provided."
  type        = list(string)
}

variable "func_pool_min_size" {
  default     = 0
  description = "The minimum size of the AutoScaling Group."
  type        = number
}

variable "func_pool_max_size" {
  default     = 5
  description = "The maximum size of the AutoScaling Group."
  type        = number
}

variable "func_pool_namespace" {
  default     = "pulsar-funcs"
  description = "The namespace where functions run."
  type        = string
}

variable "func_pool_sa_name" {
  default     = "default"
  description = "The service account name the functions use."
  type        = string
}

variable "hosted_zone_id" {
  description = "The ID of the Route53 hosted zone used by the cluster's External DNS configuration."
  type        = string
}

variable "istio_mesh_id" {
  default     = null
  description = "The ID used by the Istio mesh. This is also the ID of the StreamNative Cloud Pool used for the workload environments. This is required when \"enable_istio_operator\" is set to \"true\"."
  type        = string
}

variable "istio_network" {
  default     = "default"
  description = "The name of network used for the Istio deployment. This is required when \"enable_istio_operator\" is set to \"true\"."
  type        = string
}

variable "istio_profile" {
  default     = "default"
  description = "The path or name for an Istio profile to load. Set to the profile \"default\" if not specified."
  type        = string
}

variable "istio_revision_tag" {
  default     = "sn-stable"
  description = "The revision tag value use for the Istio label \"istio.io/rev\"."
  type        = string
}

variable "istio_trust_domain" {
  default     = "cluster.local"
  description = "The trust domain used for the Istio deployment, which corresponds to the root of a system. This is required when \"enable_istio_operator\" is set to \"true\"."
  type        = string
}

variable "istio_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values"
  type        = map(any)
}

variable "kiali_operator_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values"
  type        = map(any)
}

variable "map_additional_aws_accounts" {
  default     = []
  description = "Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap."
  type        = list(string)
}

variable "map_additional_iam_roles" {
  default     = []
  description = "Additional IAM roles to add to `config-map-aws-auth` ConfigMap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

variable "map_additional_iam_users" {
  default     = []
  description = "Additional IAM roles to add to `config-map-aws-auth` ConfigMap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
}

variable "node_termination_handler_helm_chart_name" {
  default     = "aws-node-termination-handler"
  description = "The name of the Helm chart to use for the AWS Node Termination Handler."
  type        = string
}

variable "node_termination_handler_helm_chart_repository" {
  default     = "https://aws.github.io/eks-charts"
  description = "The repository containing the Helm chart to use for the AWS Node Termination Handler."
  type        = string
}

variable "node_termination_handler_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values for the AWS Node Termination Handler. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller for available options."
  type        = map(string)
}

variable "node_termination_handler_chart_version" {
  default     = "0.16.0"
  description = "The version of the Helm chart to use for the AWS Node Termination Handler."
  type        = string
}

variable "node_pool_desired_size" {
  description = "Desired number of worker nodes in the node pool."
  type        = number
}

variable "node_pool_disk_size" {
  default     = 50
  description = "Disk size in GiB for worker nodes in the node pool. Defaults to 50."
  type        = number
}

variable "node_pool_disk_type" {
  default     = "gp3"
  description = "Disk type for worker nodes in the node pool. Defaults to gp3."
  type        = string
}

variable "node_pool_instance_types" {
  default     = ["c6i.large"]
  description = "Set of instance types associated with the EKS Node Group. Defaults to [\"c6i.large\"]."
  type        = list(string)
}

variable "node_pool_min_size" {
  description = "The minimum size of the node pool AutoScaling group."
  type        = number
}

variable "node_pool_max_size" {
  description = "The maximum size of the node pool Autoscaling group."
  type        = number
}

variable "permissions_boundary_arn" {
  default     = null
  description = "If required, provide the ARN of the IAM permissions boundary to use for restricting StreamNative's vendor access."
  type        = string
}

variable "private_subnet_ids" {
  default     = []
  description = "The ids of existing private subnets."
  type        = list(string)
}

variable "public_subnet_ids" {
  default     = []
  description = "The ids of existing public subnets."
  type        = list(string)
}

variable "region" {
  default     = null
  description = "The AWS region."
  type        = string
}

variable "service_domain" {
  default     = null
  description = "The DNS domain for external service endpoints. This must be set when enabling Istio or else the deployment will fail."
  type        = string
}

variable "sncloud_services_iam_policy_arn" {
  default     = ""
  description = "The IAM policy ARN to be used for all StreamNative Cloud Services that need to interact with AWS services external to EKS. This policy is typically created by the \"modules/managed-cloud\" sub-module in this repository, as a seperate customer driven process for managing StreamNative's Vendor Access into AWS. If no policy ARN is provided, the module will generate the policies needed by each cluster service we install and expects that the caller identity has appropriate IAM permissions that allow \"iam:CreatePolicy\" action. Otherwise the module will fail to run properly. Depends upon use"
  type        = string
}

variable "sncloud_services_lb_policy_arn" {
  default     = ""
  description = "A custom IAM policy ARN for LB load balancer controller. If not specified, and use_runt"
  type        = string
}

variable "use_runtime_policy" {
  default     = false
  description = "Indicates to use the runtime policy and attach a predefined policies as opposed to create roles. Currently defaults to false"
  type        = bool
}

variable "vpc_id" {
  default     = ""
  description = "The ID of the AWS VPC to use."
  type        = string
  validation {
    condition     = length(var.vpc_id) > 4 && substr(var.vpc_id, 0, 4) == "vpc-"
    error_message = "The value for variable \"vpc_id\" must be a valid VPC id, starting with \"vpc-\"."
  }
}

variable "wait_for_cluster_timeout" {
  default     = 0
  description = "Time in seconds to wait for the newly provisioned EKS cluster's API/healthcheck endpoint to return healthy, before applying the aws-auth configmap. Defaults to 300 seconds in the parent module \"terraform-aws-modules/eks/aws\", which is often too short. Increase to at least 900 seconds, if needed. See also https://github.com/terraform-aws-modules/terraform-aws-eks/pull/1420."
  type        = number
}
