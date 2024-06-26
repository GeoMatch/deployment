terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }

    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.1.8"
}

locals {
  efs_name = "${var.project}-${var.environment}${var.efs_name_prefix}-efs-elastic"
}

resource "aws_efs_file_system" "this" {
  encrypted              = true # TODO(P2): CMK
  availability_zone_name = var.networking_module.one_zone_az_name
  creation_token         = local.efs_name
  # TODO(P2): Document this decision
  throughput_mode = "elastic"
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = local.efs_name
  }
}

resource "aws_efs_file_system_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  # Deny any traffic that isn't secure by default
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Deny",
          "Principal" : {
            "AWS" : "*"
          },
          "Resource" : aws_efs_file_system.this.arn,
          "Action" : "*",
          "Condition" : {
            "Bool" : {
              "aws:SecureTransport" : "false"
            }
          }
        }
      ]
    }
  )
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = "ENABLED"
  }
}
