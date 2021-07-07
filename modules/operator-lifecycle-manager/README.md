# operator-lifecycle-manager
This module installs the operator lifecycle management framework using a somewhat "unnofficial" Helm chart published by [Operator Framework](https://github.com/operator-framework). For stability purposes, we will keep the chart local to this module while we wait for it to be released in an official Helm repository. 

The most recent version can be found in the `operator-framework/operator-lifecycle-manager` repo in github, [linked here](https://github.com/operator-framework/operator-lifecycle-manager/tree/master/deploy/chart).

## Usage

1. Add the cluster config to your `~/.kube/config` file, referencing the `snconf.yaml` file specific to the managed cluster you are working with _(this should be located in the customer's corresponding `managed-cluster` directory)_.

```shell
./<repo_root>/customer_env/load_env.sh snconf.yaml
```

2. Create a new `main.tf` file (or add to an existing one) and instatiate the module in the desired location _(i.e. `github.com/managed-clusters/tree/master/clusters/managed-clusters/<customer>/<cluster>/k8s-cluster-autoscaler`)_:

```hcl

provider "helm" {
  kubernetes {
    config_path = pathexpand(~/.kube/config)
  }
}

provider "kubernetes" {
  config_path = pathexpand(~/.kube/config)
}

module "operator-lifecycle-manager" {
  source       = "git@github.com:streamnative/managed-clusters.git//terraform_modules/services/operator-lifecycle-manager"
}
```

3. Initialize and apply

```shell
terraform init
terraform apply
```

4. Connect to the cluster and verify that OLM has been deployed and is healthy

## Requirements
### Providers
| Name | Version |
|------|---------|
| [terraform](https://www.terraform.io/downloads.html) | >= 0.15 |
| [kubernetes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest) | >= 2.2.0 |
| [helm](https://registry.terraform.io/providers/hashicorp/helm/latest) | >= 2.1.2 |

### Variables
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| atomic | Purge the chart on failed installation. Automatically enables `var.wait` if set to true | bool | `true` | no
| chart | The name of the helm chart to use. Defaults to the `chart` directory local to this module | string | `./chart` | no
| cleanup_on_fail | Allow deletion of new resources created in this upgrade when an upgrade fails | bool | `true` | no
| config_path | The location of your kubernetes configuration file | string | `~/.kube/config` | no
| name | The name given for the helm release being deployed | string | `operator-lifecycle-manager` | no
| namespace | The k8s namespace to be used by cluster-autoscaler | string | `operator-lifecycle-manager` | no
| timeout | Time (in seconds) to wait for any individual kubernetes operations | number | `600` | no
| wait | Wait until all resources are in a ready state before making the release as successful, per the length of `var.timeout` | bool | `true` | no
