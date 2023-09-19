resource "aws_lb" "frontend" {
  name               = "frontend"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.frontend_lb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  access_logs {
    bucket  = aws_s3_bucket.access_logs.bucket
    prefix  = "frontend_lb"
    enabled = var.debug
  }
}

resource "aws_security_group" "frontend_lb" {
  name   = "frontend-lb"
  vpc_id = aws_vpc.prod.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "frontend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.prod.id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.frontend.id
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.frontend]

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = aws_lb.frontend.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  depends_on        = [aws_lb_target_group.frontend]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  certificate_arn = aws_acm_certificate.ssl_cert.arn
}

resource "aws_lb_listener_rule" "backend_redirect" {
  listener_arn = aws_lb_listener.frontend_https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/admin*", "/graphql*", "/auth/graphql*", "/batch/*", "/static*"]
    }
  }
}
