variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "name" {
  type = string
}

variable "limit_to_su_vpn" {
  type = bool
}

variable "su_vpn_end_user_cidr" {
  # TODO: Move to global config in central account
  # https://uit.stanford.edu/guide/lna/network-numbers
  type = string
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the SSL certificate to use for HTTPS"
}

variable "acm_cert_domain" {
  type = string
  description = "ACM Certificate domain"
  default     = null
}


variable "networking_module" {
  type = object({
    vpc_id                     = string
    private_tier_tag           = string
    public_tier_tag            = string
    one_zone_az_name           = string
    one_zone_public_subnet_id  = string
    one_zone_private_subnet_id = string
    cidr_block                 = string
    tier_tag_private           = string
    tier_tag_public            = string
  })
}

variable "cognito_module" {
  type = object({
    cognito_region = string
    cognito_client_id = string
    cognito_user_pool_id = string
    cognito_client_secret = string
    cognito_redirect_uri = list(string)
    cognito_app_domain = string
    cognito_authorization_endpoint = string
    cognito_token_url = string
    cognito_user_pool_arn = string
    #cognito_email_verification_message = string
    #cognito_email_verification_subject = string
  })
  default     = null
}

variable "require_cardinal_cloud_auth" {
  type = bool
  
  validation {
    condition     = var.require_cardinal_cloud_auth == false || var.cognito_module != null
    error_message = "cognito_module must be provided when require_cardinal_cloud_auth is true"
  }
}

variable "stanford_oidc_client_id" {
  description = "Client ID for Stanford OIDC authentication"
  type        = string
  sensitive   = true
  default     = null
}

variable "stanford_oidc_client_secret" {
  description = "Client secret for Stanford OIDC authentication"
  type        = string
  sensitive   = true
  default     = null
}