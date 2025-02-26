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

locals {
  name_prefix = "${var.project}-${var.environment}-${var.name}-alb"
}

resource "aws_security_group" "alb" {
  name   = "${local.name_prefix}-sg"
  vpc_id = var.networking_module.vpc_id

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = local.name_prefix
  }

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_vpc_security_group_ingress_rule" "inbound_80" {
#   security_group_id = aws_security_group.alb.id
#   from_port         = 80
#   to_port           = 80
#   ip_protocol       = "tcp"
#   cidr_ipv4         = ["0.0.0.0/0"]

#   tags = {
#     Project     = var.project
#     Environment = var.environment
#     Name        = "${local.name_prefix}-inbound-80"
#   }
# }

resource "aws_vpc_security_group_ingress_rule" "inbound_443" {
  security_group_id = aws_security_group.alb.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.limit_to_su_vpn ? var.su_vpn_end_user_cidr : "0.0.0.0/0"

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-inbound-443"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.networking_module.vpc_id]
  }

  tags = {
    # Project = var.project TODO?
    Tier = var.networking_module.public_tier_tag
  }
}

// "If you're using Application Load Balancers, then cross-zone load balancing is always turned on."
// We only run in one AZ, but use all public subnets anyway.
resource "aws_alb" "this" {
  name               = local.name_prefix
  internal           = false
  load_balancer_type = "application"
  subnets            = [var.networking_module.one_zone_public_subnet_id, data.aws_subnets.public.ids[0]]
  security_groups    = [aws_security_group.alb.id]
  idle_timeout       = 60

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = local.name_prefix
  }
}

resource "aws_alb" "uat" {
  count              = var.require_cardinal_cloud_auth ? 1 : 0
  name               = "${local.name_prefix}-uat"
  internal           = false
  load_balancer_type = "application"
  subnets            = [var.networking_module.one_zone_public_subnet_id, data.aws_subnets.public.ids[0]]
  security_groups    = [aws_security_group.alb.id]
  idle_timeout       = 60

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-uat"
  }
}

resource "aws_lb_target_group" "uat" {
  count              = var.require_cardinal_cloud_auth ? 1 : 0
  name        = "${local.name_prefix}-uat-tg"
  target_type = "lambda"
  
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-uat-tg"
  }
}

resource "aws_lb_listener" "https-uat" {
  count              = var.require_cardinal_cloud_auth ? 1 : 0
  load_balancer_arn = aws_alb.uat[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.this[0].arn

  # dynamic authentication action using AWS Cognito, 
  # based on the require_cardinal_cloud_auth variable
  dynamic "default_action" {
    for_each = var.require_cardinal_cloud_auth ? [1] : []
    content {
      type = "authenticate-cognito"
      authenticate_cognito {
        user_pool_arn       = var.cognito_module.cognito_user_pool_arn
        user_pool_client_id = var.cognito_module.cognito_client_id
        user_pool_domain    = var.cognito_module.cognito_app_domain

        on_unauthenticated_request = "authenticate"
        scope                      = "email openid"
        session_cookie_name        = "AWSELBAuthSessionCookie"
        session_timeout           = 3600

        authentication_request_extra_params = {
          prompt = "login"
          scope = "email openid"
          response_type = "code"
          redirect_uri = var.cognito_module.cognito_redirect_uri[0]         
        }
      }
      order = 1
    }
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.uat[0].arn
    order            = 2
  }
}

data "aws_acm_certificate" "this" {
  count       = var.require_cardinal_cloud_auth ? 1 : 0
  domain      = var.acm_cert_domain
  types       = ["AMAZON_ISSUED"]
  statuses    = ["ISSUED"]
  most_recent = true
}