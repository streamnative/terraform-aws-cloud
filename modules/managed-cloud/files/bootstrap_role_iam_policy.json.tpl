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
      ],
      "Resource": "*"
    },
    {
      "Sid": "PEMBResRW",
      "Effect": "Allow",
      "Action": [
        "iam:AttachRolePolicy"
      ],
      "Resource": "arn:aws:iam::${account_id}:role/StreamNative/*"
    },
    {
      "Sid": "SecGroupVPC",
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroup*",
        "ec2:RevokeSecurityGroup*"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Vendor": "StreamNative"
        }
      }
    },
    {
      "Sid": "RunInst",
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances"
      ],
      "Resource": "*",
      "Condition": {
        "ArnLikeIfExists": {
          "ec2:Vpc": ${vpc_ids}
        }
      }
    },
    {
      "Sid": "UnResAccessRW",
      "Effect": "Allow",
      "Action": [
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:ScheduleKeyDeletion",
        "logs:CreateLogGroup",
        "logs:PutRetentionPolicy",
        "route53:CreateHostedZone",
        "route53:ChangeTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ResBasedRest",
      "Effect": "Allow",
      "Action": [
        "eks:DeleteNodeGroup",
        "iam:CreatePolicy",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicy",
        "iam:DeletePolicyVersion"
      ],
      "Resource": [
        "arn:aws:eks:${region}:${account_id}:nodegroup/*/${nodepool_pattern}/*",
        "arn:aws:iam::${account_id}:policy/StreamNative/*"
      ]
    },
    {
      "Sid": "AllowTagSNASG",
      "Effect": "Allow",
      "Action": [
        "autoscaling:CreateOrUpdateTags",
        "eks:TagResource"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/cluster-name": "${cluster_pattern}"
        }
      }
    },
    {
      "Sid": "ReqReqTag",
      "Effect": "Allow",
      "Action": [
        "acm:AddTagsToCertificate",
        "acm:ImportCertificate",
        "acm:RemoveTagsFromCertificate",
        "acm:RequestCertificate",
        "autoscaling:Create*",
        "ec2:*TransitGateway*",
        "ec2:AllocateAddress",
        "ec2:Create*",
        "eks:Create*",
        "eks:RegisterCluster",
        "eks:TagResource",
        "kms:CreateKey",
        "kms:TagResource"
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
        "autoscaling:Detach*",
        "autoscaling:Update*",
        "autoscaling:Resume*",
        "autoscaling:Suspend*",
        "autoscaling:SetDesired*",
        "ec2:AssignPrivateIpAddresses",
        "ec2:Associate*",
        "ec2:AttachInternetGateway",
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
        "ec2:TerminateInstances",
        "ec2:*TransitGateway*",
        "ec2:Update*",
        "eks:DeleteAddon",
        "eks:DeleteCluster",
        "eks:DeleteFargateProfile",
        "eks:DeregisterCluster",
        "eks:DisassociateIdentityProviderConfig",
        "eks:U*",
        "elastcloadbalancing:*Listener",
        "elastcloadbalancing:*LoadBalancer*",
        "elastcloadbalancing:*Rule",
        "elastcloadbalancing:*TargetGroup",
        "elastcloadbalancing:Set*",
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
        "s3:DeleteBucket*",
        "s3:DeleteObject*",
        "s3:DeleteLifecycle*"
       ],
       "Resource": [
          "arn:aws:s3:::${bucket_pattern}",
          "arn:aws:s3:::${bucket_pattern}/*"
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
      "Resource": [
        "arn:aws:iam::${account_id}:role/StreamNative/*"
      ],
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "eks.amazonaws.com"
        }
      }
    }
  ]
}
