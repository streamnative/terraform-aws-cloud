{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "UnrestrictedServiceAccess",
			"Effect": "Allow",
			"Action": [
				"acm:ListCertificates",
				"acm:ListTagsForCertificate",	
				"autoscaling:Describe*",
				"dynamodb:ListBackups",
				"dynamodb:ListGlobalTables",
				"dynamodb:ListTables",
				"dynamodb:ListTagsOfResource",
				"ec2:Describe*",
				"ec2:Get*",
				"eks:Describe*",
				"eks:List*",
				"iam:AttachRolePolicy",
				"iam:GetInstanceProfile",
				"iam:GetOpenIDConnectProvider",
				"iam:GetPolicy",
				"iam:GetPolicyVersion",
				"iam:GetRole",
				"iam:GetRolePolicy",
				"iam:ListAttachedRolePolicies",
				"iam:ListEntitiesForPolicy",
				"iam:ListInstanceProfile*",
				"iam:ListOpenIDConnectProvider*",
				"iam:ListPolicies",
				"iam:ListPolicyTags",
				"iam:ListPolicyVersions",
				"iam:ListRolePolicies",
				"iam:ListRoles",
				"iam:ListRoleTags",
				"kms:CreateAlias",
				"kms:CreateKey",
				"kms:DeleteAlias",
				"kms:DescribeKey",
				"kms:GetKeyPolicy",
				"kms:GetKeyRotationStatus",
				"kms:ListAliases",
				"kms:ListResourceTags",
				"kms:ScheduleKeyDeletion",
				"kms:TagResource",
				"logs:CreateLogGroup",
				"logs:DescribeLogGroups",
				"logs:ListTagsLogGroup",
				"s3:ListAllMyBuckets",
				"s3:ListBucket"
			],
			"Resource": "*"
		},
		{
			"Sid": "ResourceBasedRestictions",
			"Effect": "Allow",
			"Action": [
				"eks:DeleteNodeGroup",
				"iam:CreatePolicy",
				"iam:CreatePolicyVersion",
				"iam:DeletePolicy",
				"iam:DeletePolicyVersion"
			],
			"Resource": [
				"arn:aws:eks:${region}:${account_id}:nodegroup/*/snc-*-pool/*",
				"arn:aws:iam::${account_id}:policy/StreamNative/*"
			]
		},
		{
			"Sid": "RequireRequestTag",
			"Effect": "Allow",
			"Action": [
				"acm:AddTagsToCertificate",
				"acm:ImportCertificate",
				"acm:RemoveTagsFromCertificate",
				"acm:RequestCertificate",
				"autoscaling:CreateAutoScalingGroup",
				"autoscaling:CreateLaunchConfiguration",
				"autoscaling:CreateOrUpdateTags",
				"autoscaling:DetachInstances",
				"autoscaling:SetDesiredCapacity",
				"autoscaling:UpdateAutoScalingGroup",
				"autoscaling:SuspendProcesses",
				"ec2:AllocateAddress",
				"ec2:CreateDhcpOptions",
				"ec2:CreateEgressOnlyInternetGateway",
				"ec2:CreateInternetGateway",
				"ec2:CreateLaunchTemplate",
				"ec2:CreateNatGateway",
				"ec2:CreateNetworkInterface",
				"ec2:CreateRouteTable",
				"ec2:CreateSecurityGroup",
				"ec2:CreateSubnet",
				"ec2:CreateVolume",
				"ec2:CreateVpc",
				"ec2:CreateVpcEndpoint",
				"ec2:CreateTags",
				"ec2:RunInstances",
				"eks:Create*",
				"eks:TagResource"
			],
			"Resource": "*",
			"Condition": {
				"ForAnyValue:StringEqualsIgnoreCase": {
					"aws:RequestTag/Vendor": "StreamNative"
				}
			}
		},
		{
			"Sid": "RequireResourceTag",
			"Effect": "Allow",
			"Action": [
				"acm:DeleteCertificate",
				"acm:DescribeCertificate",
				"acm:ExportCertificate",
				"acm:GetCertificate",
				"acm:ImportCertificate",
				"acm:RemoveTagsFromCertificate",
				"acm:ResendValidationEmail",
				"autoscaling:AttachInstances",
				"autoscaling:CreateOrUpdateTags",
				"autoscaling:Delete*",
				"ec2:AllocateAddress",
				"ec2:AssignPrivateIpAddresses",
				"ec2:Associate*",
				"ec2:AttachInternetGateway",
				"ec2:AuthorizeSecurityGroup*",
				"ec2:CreateLaunchTemplateVersion",
				"ec2:CreateNatGateway",
				"ec2:CreateNetworkInterface",
				"ec2:CreateRoute",
				"ec2:CreateRouteTable",
				"ec2:CreateSecurityGroup",
				"ec2:CreateSubnet",
				"ec2:CreateTags",
				"ec2:CreateVpcEndpoint",
				"ec2:Delete*",
				"ec2:Detach*",
				"ec2:Disassociate*",
				"ec2:Modify*",
				"ec2:Release*",
				"ec2:Revoke*",
				"ec2:RunInstances",
				"ec2:Update*",
				"eks:Delete*",
				"eks:U*",
				"logs:DeleteLogGroup",
				"logs:PutRetentionPolicy"
			],
			"Resource": "*",
			"Condition": {
				"StringEqualsIgnoreCase": {
					"aws:ResourceTag/Vendor": "StreamNative"
				}
			}
		},
		{
			"Sid": "RestrictS3Access",
			"Effect": "Allow",
			"Action":[
				"s3:CreateBucket",
				"s3:DeleteBucket",
				"s3:GetAccelerateConfiguration",
				"s3:GetAccessPointPolicy",
				"s3:GetAccountPublicAccessBlock",
				"s3:GetAnalyticsConfiguration",
				"s3:GetBucket*",
				"s3:GetBucketLocation",
				"s3:GetEncryptionConfiguration",
				"s3:GetInventoryConfiguration",
				"s3:GetLifecycleConfiguration",
				"s3:GetMetricsConfiguration",
				"s3:GetReplicationConfiguration",
				"s3:PutAccelerateConfiguration",
				"s3:PutAccessPointPolicy",
				"s3:PutAccountPublicAccessBlock",
				"s3:PutAnalyticsConfiguration",
				"s3:PutBucket*",
				"s3:PutEncryptionConfiguration",
				"s3:PutInventoryConfiguration",
				"s3:PutLifecycleConfiguration",
				"s3:PutMetricsConfiguration",
				"s3:PutReplicationConfiguration"
			 ],
			 "Resource": [
				"arn:aws:s3:::*-storage-offload-*",
				"arn:aws:s3:::*-backup-*"
			 ]
			 
		},
		{
			"Sid": "RestrictDynamoAccess",
			"Effect": "Allow",
			"Action": [
				"dynamodb:*ContinuousBackups",
				"dynamodb:CreateBackup",
				"dynamodb:CreateGlobalTable",
				"dynamodb:CreateTable*",
				"dynamodb:Delete*",
				"dynamodb:Describe*",
				"dynamodb:RestoreTable*",
				"dynamodb:TagResource",
				"dynamodb:UntagResource",
				"dynamodb:Update*"
			],
			"Resource": [
				"arn:aws:dynamodb:${region}:${account_id}:table/*vault-table",
				"arn:aws:dynamodb:${region}:${account_id}:global-table/*vault-table"
			]
		},
		{
			"Sid": "IamRequireRequestTag",
			"Effect": "Allow",
			"Action": [
				"iam:CreateRole",
				"iam:CreateOpenIDConnectProvider",
				"iam:TagPolicy",
				"iam:TagRole",
				"iam:TagInstanceProfile",
				"iam:TagOpenIDConnectProvider"
			],
			"Resource": [
				"arn:aws:iam::${account_id}:role/StreamNative/*",
				"arn:aws:iam::${account_id}:policy/StreamNative/*",
				"arn:aws:iam::${account_id}:oidc-provider/*"
			],
			"Condition": {
				"StringEqualsIgnoreCase": {
					"aws:RequestTag/Vendor": "StreamNative"
				}
			}
		},
		{
			"Sid": "IamRequireResourceTag",
			"Effect": "Allow",
			"Action": [
				"iam:AddRoleToInstanceProfile",
				"iam:CreateServiceLinkedRole",
				"iam:DeleteInstanceProfile",
				"iam:DeleteOpenIDConnectProvider",
				"iam:DeleteRole",
				"iam:DeleteRolePolicy",
				"iam:DeleteServiceLinkedRole",
				"iam:DetachRolePolicy",
				"iam:PutRolePermissionsBoundary",
				"iam:PutRolePolicy",
				"iam:RemoveRoleFromInstanceProfile",
				"iam:SetDefaultPolicyVersion",
				"iam:UpdateAssumeRolePolicy",
				"iam:UpdateOpenIDConnectProviderThumbprint",
				"iam:UpdateRole",
				"iam:UpdateRoleDescription"
			],
			"Resource": [
				"arn:aws:iam::${account_id}:role/StreamNative/*",
				"arn:aws:iam::${account_id}:policy/StreamNative/*",
				"arn:aws:iam::${account_id}:oidc-provider/*"
			],
			"Condition": {
				"StringEqualsIgnoreCase": {
					"aws:ResourceTag/Vendor": "StreamNative"
				}
			}
		},
		{
			"Sid": "RestrictPassRoleToEKS",
			"Effect": "Allow",
			"Action": [
				"iam:PassRole"
			],
			"Resource": "*",
			"Condition": {
				"StringEquals": {
					"iam:PassedToService": "eks.amazonaws.com"
				}
			}
		}
	]
}