variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "app_cpu" {
  type    = number
  default = 2048
}

variable "app_memory" {
  type    = number
  default = 8192 # MB
}

variable "container_port" {
  type    = number
  default = 8787
}

variable "ecr_repo_url" {
  type = string
}

variable "ecr_tag" {
  type = string
}

variable "acm_cert_domain" {
  type        = string
  description = "ACM domain. Must have a matching ACM certificate"
}

variable "private_subnet_cidr_block" {
  type        = string
  description = "The CIDR block for the ECS service and associated resources."
}

variable "ecs_environment_variables" {
  description = "Extra ECS task def env vars"
  type = list(object({
    name  = string # Name of env variable 
    value = string
  }))
  default = []
}

variable "ecs_secrets" {
  description = "Extra ECS task def secrets (from SSM). Parent module much attach SSM policy to ECS task role."
  type = list(object({
    name      = string # Name of env variable 
    valueFrom = string # Arn of SSM parameter
  }))
  default = []
}

variable "efs_configs" {
  type = map(object({
    file_system_id = string
    volume_name    = string # Docker volume name
    mount_path     = string # Docker mount path (i.e. '/data')
    # Path to mount on EFS (i.e. '/data')
    # Will be created by the root user if it does not exist.
    root_directory = string
    # Grant root access to the EFS dir. Likely required if root_directory does not already exist.
    root_access = bool
    # If true, EFS will be mounted as read-only Docker volume.
    read_only          = bool
    mount_target_sg_id = string

    # https://repost.aws/knowledge-center/efs-access-point-configurations
    # Set the following uid/g variables to empty string to remove block
    root_dir_creator_uid_gid_number     = string
    root_dir_creation_posix_permissions = number
    # Any client using this AP will act as logged-in user 
    ap_user_uid_gid_number = string
  }))
  default = {}
}

variable "s3_configs" {
  type = map(object({
    bucket_name         = string
    bucket_name_env_var = string
    arn                 = string
  }))
  default = {}
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "health_check_skip" {
  type    = bool
  default = false
}

variable "nat_gateway_module" {
  type = object({
    nat_gateway_id = string
  })
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

variable "cloudwatch_module" {
  type = object({
    log_group_prefix            = string
    log_group_retention_in_days = number
    kms_arn                     = string
  })
}


variable "alb_module" {
  type = object({
    alb_arn    = string
    alb_sg_arn = string
    alb_sg_id  = string
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