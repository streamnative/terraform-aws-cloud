# OLM Subscription Module	
This module creates the OLM subscriptions necessary to manage the StreamNative, et al, Operators
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.olm_subscriptions](https://registry.terraform.io/providers/hashicorp/helm/2.2.0/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_catalog_namespace"></a> [catalog\_namespace](#input\_catalog\_namespace) | The namespace used by OLM and its resources | `string` | `"olm"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace used for the pulsar operator deployment | `string` | n/a | yes |
| <a name="input_settings"></a> [settings](#input\_settings) | Additional settings which will be passed to the Helm chart values | `map(any)` | `{}` | no |

## Outputs

No outputs.
