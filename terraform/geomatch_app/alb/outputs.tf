output "alb_arn" {
  value = aws_alb.this.arn
}

output "uat_alb_arn" {
  value = var.require_cardinal_cloud_auth ? aws_alb.uat[0].arn : null
}

output "alb_sg_arn" {
  value = aws_security_group.alb.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "target_group_arn" {
  value = var.require_cardinal_cloud_auth ? aws_lb_target_group.uat[0].arn : null
  description = "ARN of the target group"
}

output "target_group_oauth_callback_arn" {
  value = var.require_cardinal_cloud_auth ? aws_lb_target_group.oauth_callback[0].arn : null
  description = "ARN of the target group for OAuth2 callback"
}

output "listener_arn" {
  value = var.require_cardinal_cloud_auth ? aws_lb_listener.https-uat[0].arn : null
  description = "ARN of the listener"
}

output "alb_subnet_ids" {
  value = aws_alb.this.subnets
}
