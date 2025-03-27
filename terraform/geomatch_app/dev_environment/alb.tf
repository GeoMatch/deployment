resource "aws_lb_target_group" "this" {
  name        = "${var.project}-${var.name}" # Only 32 chars
  port        = local.container_port_num
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.networking_module.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "20"
    path                = var.health_check_path
    unhealthy_threshold = "3"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


resource "aws_lb_target_group" "oauth_callback" {
  name        = "${var.project}-${var.name}-callback"
  target_type = "ip"
  protocol    = "HTTP"
  port        = local.container_port_num
  vpc_id      = var.networking_module.vpc_id
  
  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "20"
    path                = var.health_check_path
    unhealthy_threshold = "3"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.name}-callback"
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
  listener_arn = aws_lb_listener.https.arn
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = var.alb_module.alb_arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.this.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # TODO(P2): Consider listener rules to suppliment Stanford-VPN limited security group rule
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = var.alb_module.alb_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
