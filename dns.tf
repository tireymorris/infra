resource "aws_acm_certificate" "ssl_cert" {
  domain_name       = "${var.subdomain}.${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "zone" {
  name = var.domain
}

resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = var.subdomain
  type    = "A"

  alias {
    name                   = aws_lb.frontend.dns_name
    zone_id                = aws_lb.frontend.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_listener_certificate" "ssl_cert" {
  listener_arn    = aws_lb_listener.frontend_https.arn
  certificate_arn = aws_acm_certificate.ssl_cert.arn
}
