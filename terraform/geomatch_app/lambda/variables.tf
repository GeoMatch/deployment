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