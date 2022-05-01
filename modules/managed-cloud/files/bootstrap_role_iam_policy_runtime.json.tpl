{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "UnResAccessRO",
			"Effect": "Allow",
			"Action": [
				"acm:ListCertificates",
				"acm:ListTagsForCertificate",
				"autoscaling:Describe*",
				"ec2:Describe*",
				"ec2:Get*",
				"eks:Describe*",
				"eks:List*",
				"iam:GetInstanceProfile",
				"iam:GetOpenIDConnectProvider",
				"iam:GetPolicy",
				"iam:GetPolicyVersion",
				"iam:GetRole",
				"iam:List*",
				"kms:DescribeKey",
				"kms:GetKeyPolicy",
				"kms:GetKeyRotationStatus",
				"kms:ListAliases",
				"kms:ListResourceTags",
				"logs:Describe*",
				"logs:List*",
				"route53:GetChange",
				"route53:GetHostedZone",
				"route53:ListHostedZones",
				"route53:ListTagsForResource",
				"s3:ListAllMyBuckets",
				"s3:ListBucket"
			]
		},
		{
			"Sid": "PEMBResRW",
			"Effect": "Allow",
			"Action": [
				"iam:AttachRolePolicy"
			],
			"Resource": "*"
		},
		{
			"Sid": "UnResAccessRW",
			"Effect": "Allow",
			"Action": [
				"ec2:AuthorizeSecurityGroup*",
				"ec2:RevokeSecurityGroup*"
			],
			"Resource": "*",
			"Condition": {
			 "ArnLike": {
						"ec2:Vpc": "arn:aws:ec2:${region}:${account_id}:vpc/${vpc_id}"
				}
			}
		},
		{
			"Sid": "UnResAccessRW",
			"Effect": "Allow",
			"Action": [
				"kms:CreateAlias",
				"kms:CreateKey",
				"kms:DeleteAlias",
				"kms:ScheduleKeyDeletion",
				"kms:TagResource",
				"logs:CreateLogGroup",
				"route53:CreateHostedZone",
				"route53:ChangeTagsForResource"
			],
			"Resource": "*"
		},
		{
			"Sid": "ResBasedRest",
			"Effect": "Allow",
			"Action": [
				"eks:DeleteNodeGroup"
			],
			"Resource": [
				"arn:aws:eks:${region}:${account_id}:nodegroup/*/snc-*-pool*/*"
			]
		},
		{
			"Sid": "AllowTagSNASG",
			"Effect": "Allow",
			"Action": [
				"autoscaling:CreateOrUpdateTags",
				"eks:TagResource"
			],
			"Resource": "*"
			"Condition": {
				"StringLike": {
					"aws:RequestTag/cluster-name": "sn-*"
				}
			}
		},
		{
			"Sid": "ReqReqTag",
			"Effect": "Allow",
			"Action": [
				"acm:*Certificate",
				"autoscaling:Create*",
				"autoscaling:Detach*",
				"autoscaling:SetDesired*",
				"autoscaling:Update*",
				"autoscaling:Suspend*",
				"ec2:*TransitGateway*",
				"ec2:AllocateAddress",
				"eks:Create*",
				"eks:RegisterCluster",
				"eks:TagResource",
				"elasticloadbalancer:*Listener,
				"elasticloadbalancer:*LoadBalancer*,
				"elasticloadbalancer:*Rule",
				"elasticloadbalancer:*TargetGroup",
				"elasticloadbalancer:Set*
			],
			"Resource": "*",
			"Condition": {
				"StringEquals": {
					"aws:RequestTag/Vendor": "StreamNative"
				}
			}
		},
		{
			"Sid": "ReqResTag",
			"Effect": "Allow",
			"Action": [
				"acm:*Certificate",
				"autoscaling:AttachInstances",
				"autoscaling:CreateOrUpdateTags",
				"autoscaling:Delete*",
				"ec2:AssignPrivateIpAddresses",
				"ec2:Associate*",
				"ec2:AttachInternetGateway",
				"ec2:Create*",
				"ec2:Delete*",
				"ec2:Detach*",
				"ec2:Disassociate*",
				"ec2:Modify*",
				"ec2:Release*",
				"ec2:Revoke*",
				"ec2:RunInstances",
				"ec2:TerminateInstances",
				"ec2:*TransitGateway*",
				"ec2:Update*",
				"eks:DeleteAddon",
				"eks:DeleteCluster",
				"eks:DeleteFargateProfile",
				"eks:DeregisterCluster",
				"eks:DisassociateIdentityProviderConfig",
				"eks:U*",
				"logs:DeleteLogGroup",
				"logs:PutRetentionPolicy"
			],
			"Resource": "*",
			"Condition": {
				"StringEquals": {
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
				"s3:Get*",
				"s3:List*",
				"s3:PutBucket*",
				"s3:PutObject*",
				"s3:PutLifecycle*",
				"s3:PutAccelerateConfiguration",
				"s3:PutAccessPointPolicy",
				"s3:PutAccountPublicAccessBlock",
				"s3:PutAnalyticsConfiguration",
				"s3:DeleteBucket*"
				"s3:DeleteObject*"
				"s3:DeleteLifecycle*"
			 ],
			 "Resource": [
					"arn:aws:s3:::sn-*",
					"arn:aws:s3:::sn-*/*",
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
				"StringEquals": {
					"aws:RequestTag/Vendor": "StreamNative"
				}
			}
		},
		{
			"Sid": "IamRequireResourceTag",
			"Effect": "Allow",
			"Action": [
				"iam:AddRoleToInstanceProfile",
				"iam:DeleteInstanceProfile",
				"iam:DeleteOpenIDConnectProvider",
				"iam:DeleteRole",
				"iam:DeleteServiceLinkedRole",
				"iam:DetachRolePolicy",
				"iam:PutRolePermissionsBoundary",
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
				"StringEquals": {
					"aws:ResourceTag/Vendor": "StreamNative"
				}
			}
		},
		{
			"Sid": "AllowAWSServiceRoleCreation",
			"Effect": "Allow",
			"Action": "iam:CreateServiceLinkedRole",
			"Resource": "arn:aws:iam::${account_id}:role/aws-service-role/*"
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
