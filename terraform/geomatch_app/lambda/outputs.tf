output "function_arn" {
  value       = aws_lambda_function.alb_lambda.arn
  description = "ARN of the Lambda function"
}

output "function_name" {
  value       = aws_lambda_function.alb_lambda.function_name
  description = "Name of the Lambda function"
}

variable "target_group_arn" {
  type        = string
  description = "ARN of the ALB target group"
}