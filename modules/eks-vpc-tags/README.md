# eks-vpc-tags
This module adds the resource tags necessary for allowing Kubernetes ingress controllers to automatically discover available AWS subnets.

Just pass in the VPC ID, a list of private or public subnets, and the name of your EKS and the module will create the necessary tags.

