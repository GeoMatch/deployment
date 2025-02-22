variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ecr_name_suffix" {
  type    = string
  default = "app"
}

variable "ssm_name_prefix" {
  type        = string
  description = "should be '/{project}/{environment}'"
}

// Cognito variables for the user pool in a given region and environment
variable "cognito_region" {
  description = "The region where the user pool is created"
  type = string
}


variable "cognito_redirect_uri" {
  description = "The redirect URI of the user pool"
  type = list(string)
}

// Cognito variables for the user pool in a given region and environment
variable "cognito_email_verification_message" {
  type = string
}

variable "cognito_email_verification_subject" {
  type = string
}

variable "cognito_admin_create_user_message" {
  type = string
}

variable "cognito_admin_create_user_subject" {
  type = string
}

variable "cognito_allow_email_address" {
  type = string
}

variable "subdomain" {
  description = "Subdomain for the application (e.g., 'us')"
  type        = string
}

variable "domain" {
  description = "The domain for the Cognito callback URLs"
  type        = string
}