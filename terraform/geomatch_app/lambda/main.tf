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
        }
                
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Create the Lambda permission to allow ALB invocation
resource "aws_lambda_permission" "allow_alb" {
  statement_id  = "AllowALBInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alb_lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = var.target_group_arn
}

# Create the target group attachment
resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = var.target_group_arn
  target_id        = aws_lambda_function.alb_lambda.function_arn
  depends_on       = [aws_lambda_permission.allow_alb]
}