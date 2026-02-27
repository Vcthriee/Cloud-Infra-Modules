
# ACM CERTIFICATE - SSL/TLS FOR DOMAIN
# Free certificate from AWS

resource "aws_acm_certificate" "main" {
  # Primary domain
  domain_name = var.domain_name
  
  # Also cover subdomains
  subject_alternative_names = ["*.${var.domain_name}"]
  
  # Validate via DNS (add TXT records)
  validation_method = "DNS"

  tags = {
    Name = "${var.project_name}-cert"
  }

  # Create new before destroying (for renewals)
  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Wait for validation to complete
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}