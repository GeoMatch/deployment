output "alb_arn" {
  value = aws_alb.this.arn
}

output "uat_alb_arn" {
  value = aws_alb.uat.arn
}

output "alb_sg_arn" {
  value = aws_security_group.alb.arn
}

output "uat_alb_sg_arn" {
  value = aws_security_group.uat.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "uat_alb_sg_id" {
  value = aws_security_group.uat.id
}

output "target_group_arn" {
  value = aws_lb_target_group.uat.arn
  description = "ARN of the target group"
}

output "listener_arn" {
  value = aws_lb_listener.https-uat.arn
  description = "ARN of the listener"
}
