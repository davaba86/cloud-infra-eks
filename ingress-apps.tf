variable "cluster_lb" {
  description = "AWS LB DNS which is generated once the svc nginx-ingress is created."
  default     = "aws_lb_dns"
}

variable "domain" {
  description = "Your own domain, for eg. Route53."
  default     = "my_domain"
}

variable "my_zone" {
  description = "Your own Route53 domain zone ID."
  default     = "my_dns_zone_id"
}

resource "aws_route53_record" "app_web1" {
  zone_id = var.my_zone
  name    = "web1.${var.domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.cluster_lb]
}

resource "aws_route53_record" "app_metrics" {
  zone_id = var.my_zone
  name    = "metrics.${var.domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.cluster_lb]
}

resource "aws_route53_record" "app_dashboard" {
  zone_id = var.my_zone
  name    = "dashboard.${var.domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.cluster_lb]
}

resource "aws_route53_record" "app_db1_exporter" {
  zone_id = var.my_zone
  name    = "db1-exporter.${var.domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.cluster_lb]
}

resource "aws_route53_record" "app_db2_exporter" {
  zone_id = var.my_zone
  name    = "db2-exporter.${var.domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.cluster_lb]
}
