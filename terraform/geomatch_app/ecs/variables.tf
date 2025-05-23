# --------------------------------------------------------------------
#  REQUIRED
# --------------------------------------------------------------------
variable "aws_region" {
  type = string
}

# Should not include the value of `vars.environment`
# e.g. geomatch-us 
variable "project" {
  type = string
}

variable "environment" {
  description = "One of [prod,staging]"
  type        = string

  validation {
    condition     = var.environment == "prod" || var.environment == "staging"
    error_message = "Environment must be prod or staging."
  }
}

variable "github_geomatch_app_repo" {
  type        = string
  description = "e.g. org_name/repo_name"
}

variable "geomatch_subdomain" {
  description = "e.g. 'swiss' will become 'swiss.geomatch.org'"
  type        = string
}

variable "networking_module" {
  type = object({
    vpc_id                     = string
    private_tier_tag           = string
    public_tier_tag            = string
    one_zone_az_name           = string
    one_zone_public_subnet_id  = string
    one_zone_private_subnet_id = string
  })
}

variable "cloudwatch_module" {
  type = object({
    log_group_prefix            = string
    log_group_retention_in_days = number
    kms_arn                     = string
  })
}

variable "ecr_module" {
  sensitive = true
  type = object({
    geomatch_app_ecr_repo_url   = string
    geomatch_app_container_port = number
  })
}

variable "ses_module" {
  sensitive = true
  type = object({
    smtp_host          = string
    smtp_host_user     = string
    smtp_host_password = string
    sender_domain      = string
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
}

variable "efs_module" {
  sensitive = true
  type = object({
    file_system_id  = string
    file_system_arn = string
  })
}

variable "ssm_name_prefix" {
  type        = string
  description = "should be '/{project}/{environment}'"
}

variable "geomatch_version" {
  type = string
}


# --------------------------------------------------------------------
#  OPTIONAL
# --------------------------------------------------------------------

variable "route_53_zones" {
  type        = list(string)
  description = "The names of the route53 zone if used (e.g. refugeematching.org). By default, all records are created with GoDaddy."
  default     = null
}

variable "app_cpu" {
  type    = number
  default = 256 # .25 vCPU 
}

variable "app_memory" {
  type    = number
  default = 512 # MB
}

variable "ephemeral_storage_size" {
  description = "The amount of ephemeral storage (in GiB) to allocate to the task. Min 21, max 200."
  type        = number
  default     = 21  # AWS Fargate default
  
  validation {
    condition     = var.ephemeral_storage_size >= 21 && var.ephemeral_storage_size <= 200
    error_message = "Ephemeral storage size must be between 21 and 200 GiB."
  }
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_log_retention" {
  type    = number
  default = 8640 # minutes == 6 days
}

variable "alb_certificate_arn" {
  type        = string
  description = "Include if you want to override geomatch.org cert. Defaults to a cert for [var.geomatch_subdomain].geomatch.org"
  default     = null
}