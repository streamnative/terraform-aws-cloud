# Changelog

## [3.3.0](https://github.com/streamnative/terraform-aws-cloud/compare/v3.2.0...v3.3.0) (2024-11-03)


### Features

* add new variables for forward compatibility ([#142](https://github.com/streamnative/terraform-aws-cloud/issues/142)) ([269b38f](https://github.com/streamnative/terraform-aws-cloud/commit/269b38fbc31e9464921ddf046629fb4ccaee7c4c))

## [3.2.0](https://github.com/streamnative/terraform-aws-cloud/compare/v3.1.0...v3.2.0) (2024-09-10)


### Features

* Expose route tables info ([#138](https://github.com/streamnative/terraform-aws-cloud/issues/138)) ([13d1412](https://github.com/streamnative/terraform-aws-cloud/commit/13d141209539f4ef25eae9f87284eba0c0397170))

## [3.1.0](https://github.com/streamnative/terraform-aws-cloud/compare/v3.0.0...v3.1.0) (2024-06-30)


### Features

* add availability_zones to vpc module ([#135](https://github.com/streamnative/terraform-aws-cloud/issues/135)) ([c85f5e2](https://github.com/streamnative/terraform-aws-cloud/commit/c85f5e2b737d12543262b6502ac01576879d6113))

## [3.0.0](https://github.com/streamnative/terraform-aws-cloud/compare/v2.8.0...v3.0.0) (2024-05-21)


### ⚠ BREAKING CHANGES

* use shared route table for public subnet ([#125](https://github.com/streamnative/terraform-aws-cloud/issues/125))

### Features

* add new output eks which contains all outputs of module.eks ([#131](https://github.com/streamnative/terraform-aws-cloud/issues/131)) ([6f7739e](https://github.com/streamnative/terraform-aws-cloud/commit/6f7739eb8d41f6dfb971cc2eee6f7c9713977432))
* add output eks for provide convenient approach to access eks module's all outputs ([6f7739e](https://github.com/streamnative/terraform-aws-cloud/commit/6f7739eb8d41f6dfb971cc2eee6f7c9713977432))
* **cluster_autoscaler:** removed old k8s versions, added new ones ([#120](https://github.com/streamnative/terraform-aws-cloud/issues/120)) ([853aba8](https://github.com/streamnative/terraform-aws-cloud/commit/853aba86bd144b3462947f02ce83513569cd67af))
* Disable nodepool logging to cloudwatch by default ([#126](https://github.com/streamnative/terraform-aws-cloud/issues/126)) ([c9be3c1](https://github.com/streamnative/terraform-aws-cloud/commit/c9be3c188be0ab67927c799b52c1d88e6f3bb1e6))
* support disable nat gateway and use public subnet ([#132](https://github.com/streamnative/terraform-aws-cloud/issues/132)) ([4c1b508](https://github.com/streamnative/terraform-aws-cloud/commit/4c1b508055a51ab9a8df3efd92785a6ac9c95736))
* Support single zone node_group ([#133](https://github.com/streamnative/terraform-aws-cloud/issues/133)) ([8038bdf](https://github.com/streamnative/terraform-aws-cloud/commit/8038bdf08874221ac2778253148a97bd0c04aa8c))
* use shared route table for public subnet ([#125](https://github.com/streamnative/terraform-aws-cloud/issues/125)) ([12e5ff0](https://github.com/streamnative/terraform-aws-cloud/commit/12e5ff074f4dfb03d8804ccfdc6adbaa55198400))


### Bug Fixes

* Correct default value ([#128](https://github.com/streamnative/terraform-aws-cloud/issues/128)) ([25d8171](https://github.com/streamnative/terraform-aws-cloud/commit/25d8171ff57a4bb83d697c718289b12cb3030b6a))
* Optimize external-dns args to reduce api calls ([#124](https://github.com/streamnative/terraform-aws-cloud/issues/124)) ([5aa0166](https://github.com/streamnative/terraform-aws-cloud/commit/5aa01668a2735698d7ede1e31354e11529fe0710))

## [2.8.0](https://github.com/streamnative/terraform-aws-cloud/compare/v2.7.0...v2.8.0) (2023-08-24)


### Features

* upgrade istio chart to v0.8.6 ([#116](https://github.com/streamnative/terraform-aws-cloud/issues/116)) ([9cff6cc](https://github.com/streamnative/terraform-aws-cloud/commit/9cff6ccc5e5af0d9bb4814eb9fbe2d1e7bf02ece))

## [2.7.0](https://github.com/streamnative/terraform-aws-cloud/compare/v2.6.0...v2.7.0) (2023-07-28)


### Features

* support custom cluster service CIDR ([#108](https://github.com/streamnative/terraform-aws-cloud/issues/108)) ([e179318](https://github.com/streamnative/terraform-aws-cloud/commit/e17931884a4b1d6795621f8b9a61d3b4e79bef2f))


### Bug Fixes

* set create_iam_policies default to false ([#109](https://github.com/streamnative/terraform-aws-cloud/issues/109)) ([2c4c2b3](https://github.com/streamnative/terraform-aws-cloud/commit/2c4c2b3842b16e884f1bb41b8b66aec0addc6812))
* set create_iam_policies to false ([2c4c2b3](https://github.com/streamnative/terraform-aws-cloud/commit/2c4c2b3842b16e884f1bb41b8b66aec0addc6812))
