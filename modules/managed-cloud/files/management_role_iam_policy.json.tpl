{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowedServices",
      "Effect": "Allow",
      "Action": [
        "acm:List*",
        "cloudwatch:Describe*",
        "cloudwatch:List*",
        "cloudwatch:Get*",
        "logs:Describe*",
        "logs:List*",
        "logs:Filter*",
        "logs:StartQuery",
        "logs:StopQuery",
        "route53:Get*",
        "route53:List*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowedIAMReadActions",
      "Effect": "Allow",
      "Action": [
        "iam:GetPolicy*",
        "iam:GetRole*",
        "iam:ListRole*",
        "iam:ListPolic*"
      ],
      "Resource": [
        "arn:aws:iam::${account_id}:role/StreamNative/*",
        "arn:aws:iam::${account_id}:policy/StreamNative/*",
        "arn:aws:iam::aws:policy/*"
      ]
    },
    {
      "Sid": "IamRequireRequestTag",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:TagRole"
      ],
      "Resource": [
        "arn:aws:iam::${account_id}:role/StreamNative/*"
      ],
      "Condition": {
        "StringEqualsIgnoreCase": {
          "aws:RequestTag/Vendor": "StreamNative"
        }
      }
    },
    {
      "Sid": "IamAttach",
      "Effect": "Allow",
      "Action": [
        "iam:AttachRolePolicy"
      ],
      "Resource": "arn:aws:iam::${account_id}:role/StreamNative/*",
      "Condition": {
        "ArnEquals": {
          "iam:PolicyARN": [
            "arn:aws:iam::${account_id}:policy/StreamNative/StreamNativeCloudManagementPolicy"
          ]
        }
      }
    },
    {
      "Sid": "IamRequireResourceTag",
      "Effect": "Allow",
      "Action": [
        "iam:DeleteRole",
        "iam:DetachRolePolicy",
        "iam:PutRolePermissionsBoundary",
        "iam:SetDefaultPolicyVersion",
        "iam:UpdateAssumeRolePolicy",
        "iam:UpdateRole",
        "iam:UpdateRoleDescription"
      ],
      "Resource": [
        "arn:aws:iam::${account_id}:role/StreamNative/*",
        "arn:aws:iam::${account_id}:policy/StreamNative/*"
      ],
      "Condition": {
        "StringEqualsIgnoreCase": {
          "aws:ResourceTag/Vendor": "StreamNative"
        }
      }
    },
    {
      "Sid": "RequireResourceTag",
      "Effect": "Allow",
      "Action": [
        "acm:DeleteCertificate",
        "acm:DescribeCertificate",
        "acm:GetCertificate",
        "autoscaling:CancelInstanceRefresh",
        "autoscaling:Describe*",
        "autoscaling:PutScalingPolicy",
        "autoscaling:ResumeProcesses",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:StartInstanceRefresh",
        "autoscaling:SuspendProcesses",
        "autoscaling:UpdateAutoScalingGroup",
        "ec2:Describe*",
        "ec2:Get*",
        "eks:Describe*",
        "eks:List*",
        "eks:UpdateNodegroupConfig",
        "eks:UpdateNodegroupVersion",
        "elasticloadbalancing:Describe*"
      ],
      "Resource": [
        "*"
      ],
      "Condition": {
        "StringEqualsIgnoreCase": {
          "aws:ResourceTag/Vendor": "StreamNative"
        }
      }
    },
    {
      "Sid": "RequireRequestTag",
      "Effect": "Allow",
      "Action": [
        "acm:AddTagsToCertificate",
        "acm:ImportCertificate"
      ],
      "Resource": [
        "*"
      ],
      "Condition": {
        "StringEqualsIgnoreCase": {
          "aws:RequestTag/Vendor": "StreamNative"
        }
      }
    }
  ]
}
