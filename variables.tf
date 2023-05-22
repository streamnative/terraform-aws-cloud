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

variable "s3_encryption_kms_key_arn" {
  default     = ""
  description = "KMS key ARN to use for S3 encryption. If not set, the default AWS S3 key will be used."
  type        = string
}

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
  default     = "1.4.2"
  description = "The version of the Helm chart to use for the AWS Load Balancer Controller. The current version can be found in github: https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/Chart.yaml."
  type        = string
}

variable "aws_load_balancer_controller_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values for the AWS Load Balancer Controller. See https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller for available options."
  type        = map(string)
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
  default     = "0.6.2"
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
  default     = "9.21.0"
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

variable "cluster_name" {
  default     = ""
  description = "The name of your EKS cluster and associated resources. Must be 16 characters or less."
  type        = string

  validation {
    condition     = can(length(var.cluster_name) <= 16)
    error_message = "The value for variable \"cluster_name\" must be a string of 16 characters or less."
  }
}

variable "cluster_security_group_additional_rules" {
  default     = {}
  description = "Additional rules to add to the cluster security group. Set source_node_security_group = true inside rules to set the node_security_group as source."
  type        = any
}

variable "cluster_security_group_id" {
  default     = ""
  description = "The ID of an existing security group to use for the EKS cluster. If not provided, a new security group will be created."
  type        = string
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
  default     = "2.8.0"
  description = "Helm chart version for CSI"
  type        = string
}

variable "csi_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/charts/aws-ebs-csi-driver/values.yaml for available options."
  type        = map(any)
}

variable "create_cluster_security_group" {
  default     = true
  description = "Whether to create a new security group for the EKS cluster. If set to false, you must provide an existing security group via the cluster_security_group_id variable."
  type        = bool
}

variable "create_iam_policies" {
  default     = false 
  description = "Whether to create IAM policies for the IAM roles. If set to false, the module will default to using existing policy ARNs that must be present in the AWS account"
  type        = bool
}

variable "create_node_security_group" {
  default     = true
  description = "Whether to create a new security group for the EKS nodes. If set to false, you must provide an existing security group via the node_security_group_id variable."
  type        = bool
}

variable "disable_public_eks_endpoint" {
  default     = false
  description = "Whether to disable public access to the EKS control plane endpoint. If set to \"true\", additional configuration is required in order for the cluster to function properly, such as AWS PrivateLink for EC2, ECR, and S3, along with a VPN to access the EKS control plane. It is recommended to keep this setting to \"false\" unless you are familiar with this type of configuration."
  type        = bool
}

variable "disable_public_pulsar_endpoint" {
  default     = false
  description = "Whether or not to make the Istio Gateway use a public facing or internal network load balancer. If set to \"true\", additional configuration is required in order to manage the cluster from the StreamNative console"
  type        = bool
}

variable "disk_encryption_kms_key_arn" {
  default     = ""
  description = "The KMS Key ARN to use for EBS disk encryption. If not set, the default EBS encryption key will be used."
  type        = string
}

variable "enable_bootstrap" {
  default     = true
  description = "Enables bootstrapping of add-ons within the cluster."
  type        = bool
}

variable "enable_istio" {
  default     = true
  description = "Allows for enabling the bootstrap of Istio explicity in scenarios where the input \"var.enable_bootstrap\" is set to \"false\"."
  type        = bool
}

variable "enable_sncloud_control_plane_access" {
  default     = true
  description = "Whether to enable access to the EKS control plane endpoint. If set to \"false\", additional configuration is required in order for the cluster to function properly, such as AWS PrivateLink for EC2, ECR, and S3, along with a VPN to access the EKS control plane. It is recommended to keep this setting to \"true\" unless you are familiar with this type of configuration."
  type        = bool
}

variable "enable_node_group_private_networking" {
  default     = true
  description = "Enables private networking for the EKS node groups (not the EKS cluster endpoint, which remains public), meaning Kubernetes API requests that originate within the cluster's VPC use a private VPC endpoint for EKS. Defaults to \"true\"."
  type        = bool
}

variable "enable_node_pool_monitoring" {
  default     = true
  description = "Enable CloudWatch monitoring for the default pool(s)."
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
  default     = "6.10.2"
  description = "Helm chart version for ExternalDNS. See https://hub.helm.sh/charts/bitnami/external-dns for updates."
  type        = string
}

variable "external_dns_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://hub.helm.sh/charts/bitnami/external-dns."
  type        = map(any)
}

variable "hosted_zone_id" {
  default     = "*"
  description = "The ID of the Route53 hosted zone used by the cluster's External DNS configuration."
  type        = string
}

variable "hosted_zone_domain_name_filters" {
  default     = []
  description = "A list domain names of the Route53 hosted zones, used by the cluster's External DNS configuration for domain filtering."
  type        = list(string)
}

variable "iam_path" {
  default     = "/StreamNative/"
  description = "An IAM Path to be used for all IAM resources created by this module. Changing this from the default will cause issues with StreamNative's Vendor access, if applicable."
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

variable "map_additional_iam_roles" {
  default     = []
  description = "A list of IAM role bindings to add to the aws-auth ConfigMap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

variable "metrics_server_helm_chart_name" {
  default     = "metrics-server"
  description = "The name of the helm release to install"
  type        = string
}

variable "metrics_server_helm_chart_repository" {
  default     = "https://kubernetes-sigs.github.io/metrics-server"
  description = "The repository containing the external-metrics helm chart."
  type        = string
}

variable "metrics_server_helm_chart_version" {
  default     = "3.8.2"
  description = "Helm chart version for Metrics server"
  type        = string
}

variable "metrics_server_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://github.com/external-secrets/kubernetes-external-secrets/tree/master/charts/kubernetes-external-secrets for available options."
  type        = map(any)
}

variable "migration_mode" {
  default     = false
  description = "Whether to enable migration mode for the cluster. This is used to migrate details from existing security groups, which have had their names and description changed in versions v18.X of the community EKS module."
  type        = bool
}

variable "migration_mode_node_sg_name" {
  default     = null
  description = "The name (not ID!) of the existing security group used by worker nodes. This is required when \"migration_mode\" is set to \"true\", otherwise the parent module will attempt to set a new security group name and destroy the existin one."
  type        = string
}

variable "node_security_group_additional_rules" {
  default     = {}
  description = "Additional ingress rules to add to the node security group. Set source_cluster_security_group = true inside rules to set the cluster_security_group as source"
  type        = any
}

variable "node_security_group_id" {
  default     = ""
  description = "An ID of an existing security group to use for the EKS node groups. If not specified, a new security group will be created."
  type        = string
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
  default     = "0.18.5"
  description = "The version of the Helm chart to use for the AWS Node Termination Handler."
  type        = string
}

variable "node_pool_ami_id" {
  default     = ""
  description = "The AMI ID to use for the EKS cluster nodes. Defaults to the latest EKS Optimized AMI provided by AWS."
  type        = string
}

variable "node_pool_disk_iops" {
  default     = 3000
  description = "The amount of provisioned IOPS for the worker node root EBS volume."
  type        = number
}

variable "node_pool_ebs_optimized" {
  default     = true
  description = "If true, the launched EC2 instance(s) will be EBS-optimized. Specify this if using a custom AMI with pre-user data."
  type        = bool
}

variable "node_pool_block_device_name" {
  default     = "/dev/nvme0n1"
  description = "The name of the block device to use for the EKS cluster nodes."
  type        = string
}

variable "node_pool_desired_size" {
  default     = 0
  description = "Desired number of worker nodes in the node pool."
  type        = number
}

variable "node_pool_disk_size" {
  default     = 100
  description = "Disk size in GiB for worker nodes in the node pool. Defaults to 50."
  type        = number
}

variable "node_pool_disk_type" {
  default     = "gp3"
  description = "Disk type for worker nodes in the node pool. Defaults to gp3."
  type        = string
}

variable "node_pool_instance_types" {
  default     = ["m6i.large", "m6i.xlarge", "m6i.2xlarge", "m6i.4xlarge", "m6i.8xlarge"]
  description = "Set of instance types associated with the EKS Node Groups. Defaults to [\"m6i.large\", \"m6i.xlarge\", \"m6i.2xlarge\", \"m6i.4xlarge\", \"m6i.8xlarge\"], which will create empty node groups of each instance type to account for any workload configurable from StreamNative Cloud."
  type        = list(string)
}

variable "node_pool_labels" {
  default     = {}
  description = "A map of kubernetes labels to add to the node pool."
  type        = map(string)
}

variable "node_pool_min_size" {
  default     = 0
  description = "The minimum size of the node pool AutoScaling group."
  type        = number
}

variable "node_pool_max_size" {
  description = "The maximum size of the node pool Autoscaling group."
  type        = number
}

variable "node_pool_pre_userdata" {
  default     = ""
  description = "The user data to apply to the worker nodes in the node pool. This is applied before the bootstrap.sh script."
  type        = string
}

variable "node_pool_taints" {
  default     = {}
  description = "A list of taints in map format to apply to the node pool."
  type        = any
}

variable "node_pool_tags" {
  default     = {}
  description = "A map of tags to add to the node groups and supporting resources."
  type        = map(string)
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
  default     = ""
  description = "When Istio is enabled, the FQDN needed specifically for Istio's authorization policies."
  type        = string
}

variable "sncloud_services_iam_policy_arn" {
  default     = ""
  description = "The IAM policy ARN to be used for all StreamNative Cloud Services that need to interact with AWS services external to EKS. This policy is typically created by StreamNative's \"terraform-managed-cloud\" module, as a seperate customer driven process for managing StreamNative's Vendor Access into AWS. If no policy ARN is provided, the module will default to the expected named policy of \"StreamNativeCloudRuntimePolicy\". This variable allows for flexibility in the event that the policy name changes, or if a custom policy provided by the customer is preferred."
  type        = string
}

variable "sncloud_services_lb_policy_arn" {
  default     = ""
  description = "A custom IAM policy ARN for LB load balancer controller. This policy is typically created by StreamNative's \"terraform-managed-cloud\" module, as a seperate customer driven process for managing StreamNative's Vendor Access into AWS. If no policy ARN is provided, the module will default to the expected named policy of \"StreamNativeCloudLBPolicy\". This variable allows for flexibility in the event that the policy name changes, or if a custom policy provided by the customer is preferred."
  type        = string
}

variable "use_runtime_policy" {
  default     = false
  description = "Legacy variable, will be deprecated in future versions. The preference of this module is to have the parent EKS module create and manage the IAM role. However some older configurations may have had the cluster IAM role managed seperately, and this variable allows for backwards compatibility."
  type        = bool
}

variable "velero_backup_schedule" {
  default     = "0 5 * * *"
  description = "The scheduled time for Velero to perform backups. Written in cron expression, defaults to \"0 5 * * *\" or \"at 5:00am every day\""
  type        = string
}

variable "velero_excluded_namespaces" {
  default     = ["kube-system", "default", "operators", "olm"]
  description = "A comma-separated list of namespaces to exclude from Velero backups. Defaults are set to [\"default\", \"kube-system\", \"operators\", \"olm\"]."
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
  default     = "2.31.8"
  description = "The version of the Helm chart to use for Velero. The current version can be found in github: https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero"
  type        = string
}

variable "velero_namespace" {
  default     = "velero"
  description = "The kubernetes namespace where Velero should be deployed."
  type        = string
}

variable "velero_plugin_version" {
  default     = "v1.5.1"
  description = "Which version of the velero-plugin-for-aws to use."
  type        = string
}

variable "velero_policy_arn" {
  default     = null
  description = "The arn for the IAM policy used by the Velero backup addon service. For enhanced security, we allow for IAM policies used by cluster addon services to be created seperately from this module. This is only required if the input \"create_iam_policy_for_velero\" is set to \"false\". If created elsewhere, the expected name of the policy is \"StreamNativeCloudVeleroBackupPolicy\"."
  type        = string
}

variable "velero_settings" {
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values for Velero. See https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero for available options"
  type        = map(string)
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

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks"
  type        = string
  default     = null
}