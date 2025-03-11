variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "target_group_arn" {
  type = string
  description = "ARN of the target load balancer fronting this lambda"
}

variable "target_group_oauth_callback_arn" {
  type = string
  description = "ARN of the target group for OAuth2 callback"
}

variable "security_group_id" {
  type = string
  description = "Security group ID for Lambda VPC"
}

variable "subnet_ids" {
  type = list(string)
}