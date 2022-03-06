variable "cluster_lb" {
  description = "AWS LB DNS which is generated once the svc nginx-ingress is created."
  default     = "changeme.elb.amazonaws.com"
}

variable "my_domain" {
  description = "Your own domain, for eg. Route53."
  default     = "changeme.com"
}

variable "my_zone" {
  description = "Your own Route53 domain zone ID."
  default     = "7W34Y5FB34757348G5G63"
}

resource "aws_route53_record" "app_web1" {
  zone_id = var.my_zone
  name    = "web1.${var.my_domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.cluster_lb]
}

resource "aws_route53_record" "app_metrics" {
  zone_id = var.my_zone
  name    = "metrics.${var.my_domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.cluster_lb]
}

resource "aws_route53_record" "app_dashboard" {
  zone_id = var.my_zone
  name    = "dashboard.${var.my_domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.cluster_lb]
}

resource "aws_route53_record" "app_db1_exporter" {
  zone_id = var.my_zone
  name    = "db1-exporter.${var.my_domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.cluster_lb]
}

resource "aws_route53_record" "app_db2_exporter" {
  zone_id = var.my_zone
  name    = "db2-exporter.${var.my_domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [var.cluster_lb]
}
