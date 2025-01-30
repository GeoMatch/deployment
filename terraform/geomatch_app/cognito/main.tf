terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }

    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.1.8"
}

resource "aws_cognito_user_pool" "this" {
  name = "${var.project}-${var.environment}-cognito"
  mfa_configuration = "ON"
  auto_verified_attributes = ["email"]

  email_configuration {
    email_sending_account = "DEVELOPER"
    from_email_address = "no-reply@geomatch.org"
    reply_to_email_address = "info@geomatch.org"
    source_arn = "arn:aws:ses:us-east-1:363170352449:identity/geomatch.org"
  }

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
    invite_message_template {
      email_message = "Welcome to GeoMatch! You have been invited to access your user account with geomatch.org. Your new username is {username} and temporary password is {####}. Please access the portal using https://us.geomatch.org/login"
      email_subject = "GeoMatch Account Invitation"
      sms_message   = "Your username is {username}. Sign up at {####} "
    }
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    temporary_password_validity_days = 7
  }

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  username_configuration {
    case_sensitive = false
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message = "Thank you for registering with GeoMatch! Your verification code is {####}"
    email_subject = "Your verification code"
  }

  schema {
    name = "email"
    attribute_data_type = "String"
    required = true
    mutable = true
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }
  
  tags = {
    Terraform = true
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name = "${var.project}-${var.environment}-cognito-client"
  user_pool_id = aws_cognito_user_pool.this.id
  generate_secret = true
  callback_urls = [
    "https://${var.subdomain}.${var.domain}/auth/callback", 
    "http://localhost:8000/callback"
  ]
  logout_urls = [
    "https://${var.subdomain}.${var.domain}/auth/login", 
    "http://localhost:8000/auth/login"
  ]
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid"]
  allowed_oauth_flows_user_pool_client = true

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH", # Allow username/password authentication
    "ALLOW_USER_SRP_AUTH",      # Allow Secure Remote Password authentication
    "ALLOW_REFRESH_TOKEN_AUTH"  # Recommended for token refresh functionality
  ]
}

resource "aws_cognito_user_pool_domain" "this" {
  domain = "${var.project}-${var.environment}-domain"
  user_pool_id = aws_cognito_user_pool.this.id  
}
