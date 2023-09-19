output "frontend_lb_domain" {
  value = aws_lb.frontend.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}
