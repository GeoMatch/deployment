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

variable "idp_metadata_url" {
  #set this to default to cognito idp 
  default = "app"
  type = string
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

variable "external_providers" {
  description = "List of external identity providers to be added to the Cognito user pool"
  type = list(object({
    provider_name = string
    provider_type = string
    metadata_url  = string
    attribute_mapping = map(string)
    identifiers = list(string)
    sign_out_flow = bool
    sign_saml_requests = bool 
    require_encrypted_assertions = bool
  }))
  default = []
}