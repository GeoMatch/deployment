output "alb_arn" {
  value = aws_alb.this.arn
}

output "uat_alb_arn" {
  value = aws_alb.uat[0].arn
}

output "alb_sg_arn" {
  value = aws_security_group.alb.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "target_group_arn" {
  value = aws_lb_target_group.uat[0].arn
  description = "ARN of the target group"
}

output "listener_arn" {
  value = aws_lb_listener.https-uat[0].arn
  description = "ARN of the listener"
}

output "alb_subnet_ids" {
  value = aws_alb.this.subnets
}
