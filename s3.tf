resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state"
  acl    = "private"
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.project_name}-access-logs"
}

resource "aws_security_group" "access_logs" {
  name        = "access-logs"
  description = "Security group for access logs bucket"
  vpc_id      = aws_vpc.prod.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_lb.id]
  }
}
