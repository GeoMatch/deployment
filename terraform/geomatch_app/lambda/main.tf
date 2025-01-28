terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

resource "aws_lambda_function" "alb_lambda" {
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "${var.project}-${var.environment}-alb-lambda"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
<<<<<<< Updated upstream
        }
=======
        }        
>>>>>>> Stashed changes
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_lambda_permission" "alb" {
  statement_id  = "AllowALBInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alb_lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = var.target_group_arn
}