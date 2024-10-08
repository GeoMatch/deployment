data "aws_iam_policy_document" "github_actions" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.app_repo}:*"]
    }
  }
  dynamic "statement" {
    for_each = var.additional_trusted_role_arns
    content {
      effect = "Allow"
      actions = [
        "sts:AssumeRole",
      ]
      principals {
        type        = "AWS"
        identifiers = [statement.value]
      }
    }
  }
}


resource "aws_iam_role" "github_action_ssm_get" {
  name = "${var.project}-${var.environment}-github-ssm-get-role"

  assume_role_policy = data.aws_iam_policy_document.github_actions.json

  inline_policy {
    name = "github-ssm-get-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:DescribeParameters",
          ]
          "Resource" : "*",
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameter*"
          ]
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "aws:ResourceTag/Project" : var.project
              "aws:ResourceTag/Environment" : var.environment
            },
          }
        },
      ]
    })
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role" "github_action_build" {
  name = "${var.project}-${var.environment}-github-build-role"

  assume_role_policy = data.aws_iam_policy_document.github_actions.json

  inline_policy {
    name = "github-build-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:UploadLayerPart"
          ],
          "Resource" : [
            var.ecr_module.geomatch_app_ecr_repo_arn
          ]
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "ecr:GetAuthorizationToken",
          ],
          "Effect" : "Allow",
          "Resource" : "*"
        }
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = var.docker_build_readable_s3_arns
    content {
      name = "github-build-s3-policy-${index(var.docker_build_readable_s3_arns, inline_policy.value)}"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            Action = [
              "s3:GetBucketLocation",
              "s3:ListBucket",
              "s3:ListBucketMultipartUploads"
            ],
            Effect = "Allow",
            Resource = flatten([
              for s3_arn in var.docker_build_readable_s3_arns : [
                s3_arn
              ]
            ])
          },
          {
            Action = [
              "s3:AbortMultipartUpload",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:GetObjectVersion",
              "s3:GetObjectVersionTagging",
              "s3:ListMultipartUploadParts"
            ],
            Effect = "Allow",
            Resource = flatten([
              for s3_arn in var.docker_build_readable_s3_arns : [
                "${s3_arn}/*"
              ]
            ])
          },
        ]
      })
    }
  }

  inline_policy {
    name = "github-sm-build-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        # {
        #   "Action" : [
        #     "ecr:BatchCheckLayerAvailability",
        #     "ecr:CompleteLayerUpload",
        #     "ecr:GetAuthorizationToken",
        #     "ecr:BatchGetImage",
        #     "ecr:InitiateLayerUpload",
        #     "ecr:PutImage",
        #     "ecr:GetDownloadUrlForLayer",
        #     "ecr:UploadLayerPart"
        #   ],
        #   "Resource" : [
        #     var.sagemaker_ecr_module.geomatch_app_ecr_repo_arn
        #   ]
        #   "Effect" : "Allow"
        # },
        {
          "Action" : [
            "ecr:GetAuthorizationToken",
          ],
          "Effect" : "Allow",
          "Resource" : "*"
        }
      ]
    })
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role" "github_action_ecs_run_task" {
  count = var.ecs_module == null ? 0 : 1
  name  = "${var.project}-${var.environment}-github-ecs-run-task-role"

  assume_role_policy = data.aws_iam_policy_document.github_actions.json

  inline_policy {
    name = "github-ecs-run-task-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        # AWS IAM doesn't support scoped task def permissions.
        # https://github.com/aws/containers-roadmap/issues/929
        {
          "Effect" : "Allow",
          "Action" : [
            "ecs:RegisterTaskDefinition",
            "ecs:ListTaskDefinitions",
            "ecs:DescribeTaskDefinition",
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ecs:ListTasks",
            "ecs:DescribeTasks",
            "ecs:RunTask",
          ],
          "Condition" : {
            "ArnEquals" : {
              "ecs:cluster" : var.ecs_module.ecs_cluster_arn
            }
          },
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "iam:PassRole"
          ],
          "Resource" : [
            var.ecs_module.ecs_task_iam_arn,
            var.ecs_module.ecs_task_execution_iam_arn,
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:DescribeParameters"
          ]
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParametersByPath",
            "ssm:GetParameters",
            "ssm:GetParameter",
          ]
          "Resource" : [
            var.ecs_module.ssm_ecs_run_task_config_arn,
            var.ecs_module.ssm_new_user_password_arn
          ]
        },
      ]
    })
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role" "github_action_terraform_plan" {
  count              = var.ecs_module == null && length(var.cloud_dev_modules) == 0 ? 0 : 1
  name               = "${var.project}-${var.environment}-github-action-terraform-plan-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions.json

  managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess", "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"]

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name
}

resource "aws_iam_policy" "github_action_terraform_apply_ecs_policy" {
  count = var.ecs_module == null && length(var.cloud_dev_modules) == 0 ? 0 : 1
  name  = "${var.project}-${var.environment}-github-action-terraform-apply-ecs-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "s3:*",
        "Effect" : "Allow",
        "Resource" : ["${data.aws_s3_bucket.state.arn}", "${data.aws_s3_bucket.state.arn}/*"]
      },
      # AWS IAM doesn't support scoped task def permissions.
      # https://github.com/aws/containers-roadmap/issues/929
      {
        "Effect" : "Allow",
        "Action" : [
          "ecs:RegisterTaskDefinition",
          "ecs:ListTaskDefinitions",
          "ecs:DescribeTaskDefinition",
          "ecs:DeregisterTaskDefinition"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecs:ListServices",
          "ecs:UpdateService",
          "ecs:ListTasks",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:RunTask",
        ],
        "Condition" : {
          "ArnEquals" : {
            "ecs:cluster" : flatten(concat(
              var.ecs_module == null ? [] : [var.ecs_module.ecs_cluster_arn],
              length(var.cloud_dev_modules) == 0 ? [] :
              [
                for dev_module in var.cloud_dev_modules : [
                  dev_module.ecs_cluster_arn,
                ]
              ]
            ))
          }
        },
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:DescribeParameters"
        ]
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:PassRole"
        ],
        "Resource" : flatten(concat(
          var.ecs_module == null ? [] : [
            var.ecs_module.ecs_task_iam_arn,
            var.ecs_module.ecs_task_execution_iam_arn,
          ],
          [
            for dev_module in var.cloud_dev_modules : [
              dev_module.ecs_task_iam_arn,
              dev_module.ecs_task_execution_iam_arn,
            ]
          ]
        ))
      },
    ]
  })
}

resource "aws_iam_policy" "github_action_terraform_apply_lambda_policy" {
  count = var.ecs_module == null ? 0 : 1
  name  = "${var.project}-${var.environment}-github-action-terraform-apply-lambda-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        # TODO: Technically needed for github CICD
        "Effect" : "Allow",
        "Action" : [
          "ssm:*",
        ]
        "Resource" : concat(
          var.ecs_module == null ? [] : [
            var.ecs_module.ssm_geomatch_version_ecs_arn,
            var.ecs_module.ssm_ecs_run_task_config_arn,
          ]
        )
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:ListFunctions"
        ]
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:*",
        ],
        "Resource" : [
          var.ecs_module.r_lambda_arn
        ]
      },
      {
        # These are needed for lambda to deploy
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        # For Lambda
        "Action" : [
          "ecr:SetRepositoryPolicy",
          "ecr:GetRepositoryPolicy",
          "ecr:InitiateLayerUpload"
        ],
        "Resource" : [
          var.ecr_module.geomatch_app_ecr_repo_arn
        ],
        "Effect" : "Allow"
      },
    ]
  })
}


resource "aws_iam_role" "github_action_terraform_apply_ecs" {
  count              = var.ecs_module == null && length(var.cloud_dev_modules) == 0 ? 0 : 1
  name               = "${var.project}-${var.environment}-github-action-terraform-apply-ecs-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions.json
  managed_policy_arns = flatten(concat(
    [aws_iam_policy.github_action_terraform_apply_ecs_policy[0].arn],
    var.ecs_module == null ? [] : [aws_iam_policy.github_action_terraform_apply_lambda_policy[0].arn],
  ))
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
