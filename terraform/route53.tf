# HOSTED ZONE
resource "aws_route53_zone" "main" {
  name = "yashjagani.com"
}

# ACM us-east-1 CLOUDFRONT CERT
resource "aws_acm_certificate" "cert_us" {
  provider          = aws.secondary
  domain_name       = "yashjagani.com"
  subject_alternative_names = ["www.yashjagani.com"]
  validation_method = "DNS"
}

# ACM eu-west-2 ALB CERT
resource "aws_acm_certificate" "cert_uk" {
  domain_name       = "api.yashjagani.com"
  validation_method = "DNS"
}

# VALIDATE us-east-1 CLOUDFRONT CERT
resource "aws_route53_record" "validation_us" {
  for_each = { for dvo in aws_acm_certificate.cert_us.domain_validation_options : dvo.domain_name => dvo }
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  zone_id = aws_route53_zone.main.zone_id
  records = [each.value.resource_record_value]
  ttl     = 60
  allow_overwrite = true
}

# VALIDATE eu-west-2 ALB CERT
resource "aws_route53_record" "validation_uk" {
  for_each = { for dvo in aws_acm_certificate.cert_uk.domain_validation_options : dvo.domain_name => dvo }
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  zone_id = aws_route53_zone.main.zone_id
  records = [each.value.resource_record_value]
  ttl     = 60
  allow_overwrite = true
}

# WAIT FOR eu-west-2 CERT
resource "aws_acm_certificate_validation" "uk" {
  certificate_arn         = aws_acm_certificate.cert_uk.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_uk : record.fqdn]
}

# WAIT FOR us-east-1 CERT
resource "aws_acm_certificate_validation" "us" {
  provider                = aws.secondary
  certificate_arn         = aws_acm_certificate.cert_us.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_us : record.fqdn]
}

# A RECORD yashjagani.com -> CloudFront
resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "yashjagani.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# A RECORD api.yashjagani.com -> ALB
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.yashjagani.com"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}