resource "aws_lb_target_group" "backend" {
  name        = "backend"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.prod.id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200"
  }
}
