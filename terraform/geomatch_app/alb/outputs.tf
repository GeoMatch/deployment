output "alb_arn" {
  value = aws_alb.this.arn
}

output "alb_dns_name" {
  value = aws_alb.this.dns_name
}

output "alb_zone_id" {
  value = aws_alb.this.zone_id
}

output "alb_sg_arn" {
  value = aws_security_group.alb.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}


output "alb_subnet_ids" {
  value = aws_alb.this.subnets
}