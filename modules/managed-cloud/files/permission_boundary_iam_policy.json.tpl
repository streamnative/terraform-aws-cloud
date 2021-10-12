{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AllowedServices",
			"Effect": "Allow",
			"Action": [
			    "acm:*",
			    "autoscaling:*",
			    "cognito-idp:*",
			    "dynamodb:*",
			    "ec2:*",
			    "ecr:*",
			    "eks:*",
			    "elasticloadbalancing:*",
			    "iam:*",
			    "kms:*",
			    "logs:*",
			    "route53:*",
			    "s3:*",
			    "shield:*",
			    "sts:*",
			    "waf-regional:*",
			    "wafv2:*"
			],
			"Resource": "*"
		},
		{
			"Sid": "AllowedIAMManagedPolicies",
			"Effect": "Deny",
			"Action": [
				"iam:AttachRolePolicy"
			],
			"Resource": "arn:aws:iam::${account_id}:role/StreamNative/*",
			"Condition": {
				"ArnNotLike": {
					"iam:PolicyARN": [ 
						"arn:aws:iam::${account_id}:policy/StreamNative/StreamNativeCloudAWSLoadBalancerControllerPolicy",
						"arn:aws:iam::${account_id}:policy/StreamNative/StreamNativeCloudCertManagerPolicy",
						"arn:aws:iam::${account_id}:policy/StreamNative/StreamNativeCloudClusterAutoscalerPolicy",
						"arn:aws:iam::${account_id}:policy/StreamNative/StreamNativeCloudCsiPolicy",
						"arn:aws:iam::${account_id}:policy/StreamNative/StreamNativeCloudExternalDnsPolicy",
						"arn:aws:iam::${account_id}:policy/StreamNative/StreamNativeCloudExternalSecretsPolicy",
						"arn:aws:iam::${account_id}:policy/StreamNative/StreamNativeCloudVeleroBackupPolicy",
						"arn:aws:iam::${account_id}:policy/StreamNative/StreamNativeCloudPermissionBoundary",
						"arn:aws:iam::${account_id}:policy/StreamNative/*-elb-sl-role-*",
						"arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
						"arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
						"arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
						"arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
						"arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
						"arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
					]
				}
			}
		},
		{
			"Sid": "RequirePermissionBoundaryForIamRoles",
			"Effect": "Allow",
			"Action": [
				"iam:CreateRole"
			],
			"Resource": "arn:aws:iam::${account_id}:role/StreamNative/*",
			"Condition": {
				"StringEqualsIgnoreCase": {
					"aws:ResourceTag/Vendor": "StreamNative",
					"iam:PermissionsBoundary": "arn:aws:iam:::policy/StreamNative/StreamNativeCloudPermissionBoundary"
				}
			}
		},
		{
			"Sid": "RestrictEditingPermissionBoundary",
			"Effect": "Deny",
			"Action": [
				"iam:CreatePolicyVersion",
				"iam:DeletePolicy",
				"iam:DeletePolicyVersion",
				"iam:DeleteRolePermissionsBoundary",
				"iam:SetDefaultPolicyVersion"
			],
			"Resource": "arn:aws:iam:::policy/StreamNative/StreamNativeCloudPermissionBoundary"
		}
	]
}