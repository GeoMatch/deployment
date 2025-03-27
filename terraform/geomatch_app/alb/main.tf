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

resource "aws_vpc_security_group_egress_rule" "internal" {
  security_group_id = aws_security_group.alb.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "tcp"
  cidr_ipv4         = var.networking_module.vpc_cidr  # Allow traffic to all instances in the VPC

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-outbound-rstudio"
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
  name               = "${local.name_prefix}"
  internal           = false
  load_balancer_type = "application"
  subnets            = [var.networking_module.one_zone_public_subnet_id, data.aws_subnets.public.ids[0]]
  security_groups    = [aws_security_group.alb.id]
  idle_timeout       = 60

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}"
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${local.name_prefix}-tg"
  target_type = "ip"
  protocol    = "HTTP"
  port        = 8787 #Default RStudio server port 
  vpc_id      = var.networking_module.vpc_id
  
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-tg"
  }
}

resource "aws_lb_target_group" "oauth_callback" {
  name        = "${local.name_prefix}-callback"
  target_type = "ip"
  protocol    = "HTTP"
  port        = 8787
  vpc_id      = var.networking_module.vpc_id
  
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-callback"
  }
}


resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.this.arn

  # First rule: OAuth2 callback path without authentication
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this.arn    
  }  
}

# Rule 1 for OAuth2 callback path without authentication
resource "aws_lb_listener_rule" "oauth_callback" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.oauth_callback.arn
  }

  condition {
    path_pattern {
      values = ["/oauth2/idpresponse", "/oauth2/idpresponse/*"]
    }
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "open-callback-rule"
  }
}

# Rule 2 for Cognito authentication for all other paths
resource "aws_lb_listener_rule" "cognito_auth" {
  listener_arn = aws_lb_listener.https-uat.arn
  priority     = 2

  action {
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
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "cognito-auth-rule"
  }
}

data "aws_acm_certificate" "this" {
  domain      = var.acm_cert_domain
  types       = ["AMAZON_ISSUED"]
  statuses    = ["ISSUED"]
  most_recent = true
}