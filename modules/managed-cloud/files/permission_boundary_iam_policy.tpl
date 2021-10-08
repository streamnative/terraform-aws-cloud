{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "UnrestrictedServiceAccess",
			"Effect": "Allow",
			"Action": [
				"ec2:Describe*",
				"ec2:Get*",
				"iam:GetInstanceProfile",
				"iam:GetOpenIDConnectProvider",
				"iam:GetPolicy",
				"iam:GetPolicyVersion",
				"iam:GetRole",
				"iam:GetRolePolicy",
				"iam:ListAttachedRolePolicies",
				"iam:ListEntitiesForPolicy",
				"iam:ListInstanceProfiles",
				"iam:ListInstanceProfilesForRole",
				"iam:ListInstanceProfileTags",
				"iam:ListOpenIDConnectProviders",
				"iam:ListOpenIDConnectProviderTags",
				"iam:ListPolicies",
				"iam:ListPolicyTags",
				"iam:ListPolicyVersions",
				"iam:ListRolePolicies",
				"iam:ListRoles",
				"iam:ListRoleTags",
				"logs:CreateLogGroup",
				"logs:DescribeLogGroups",
				"logs:ListTagsLogGroup"
			],
			"Resource": "*"
		},
		{
			"Sid": "RequireRequestTag",
			"Effect": "Allow",
			"Action": [
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
				"ec2:CreateTags"
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
				"ec2:Update*",
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
			"Sid": "RequireVendorTagAndIamPath",
			"Effect": "Allow",
			"Action": [
				"iam:AddRoleToInstanceProfile",
				"iam:AttachRolePolicy",
				"iam:CreateOpenIDConnectProvider",
				"iam:CreatePolicy",
				"iam:CreatePolicyVersion",
				"iam:CreateServiceLinkedRole",
				"iam:DeleteInstanceProfile",
				"iam:DeleteOpenIDConnectProvider",
				"iam:DeletePolicy",
				"iam:DeletePolicyVersion",
				"iam:DeleteRole",
				"iam:DeleteRolePolicy",
				"iam:DeleteServiceLinkedRole",
				"iam:DetachRolePolicy",
				"iam:PutRolePermissionsBoundary",
				"iam:PutRolePolicy",
				"iam:RemoveRoleFromInstanceProfile",
				"iam:SetDefaultPolicyVersion",
				"iam:TagInstanceProfile",
				"iam:TagOpenIDConnectProvider",
				"iam:TagPolicy",
				"iam:TagRole",
				"iam:UntagInstanceProfile",
				"iam:UntagOpenIDConnectProvider",
				"iam:UntagPolicy",
				"iam:UntagRole",
				"iam:UpdateAssumeRolePolicy",
				"iam:UpdateOpenIDConnectProviderThumbprint",
				"iam:UpdateRole",
				"iam:UpdateRoleDescription"
			],
			"Resource": [
				"arn:aws:iam:::role/StreamNative/*",
				"arn:aws:iam:::policy/StreamNative/*",
				"arn:aws:iam:::oidc-provider/*"
			],
			"Condition": {
				"StringEquals": {
					"aws:ResourceTag/Vendor": "StreamNative"
				}
			}
		},
		{
			"Sid": "RestrictPassRoleToStreamNative",
			"Effect": "Allow",
			"Action": [
				"iam:PassRole"
			],
			"Resource": "*",
			"Condition": {
				"ForAnyValue:StringEquals": {
					"aws:ResourceTag/Vendor": "StreamNative"
				}
			}
		},
		{
			"Sid": "RequirePermissionBoundaryForIamRoles",
			"Effect": "Allow",
			"Action": [
				"iam:CreateRole"
			],
			"Resource": "arn:aws:iam:::role/StreamNative/*",
			"Condition": {
				"StringEquals": {
					"iam:PermissionsBoundary": "arn:aws:iam:::policy/StreamNative/StreamNativeCloudPermissionBoundary",
					"aws:ResourceTag/Vendor": "StreamNative"
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