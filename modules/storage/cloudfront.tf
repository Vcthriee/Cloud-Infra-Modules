
# CLOUDFRONT ORIGIN ACCESS IDENTITY
# Allows CloudFront to read private S3 bucket

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "OAI for ${var.project_name} assets"
}

# CLOUDFRONT DISTRIBUTION - GLOBAL CDN
# Caches content at edge locations worldwide

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} CDN"
  default_root_object = "index.html"
  
  # Price class - where to cache (North America + Europe = cheapest)
  price_class = "PriceClass_100"

  # ORIGIN 1: ALB (dynamic content)
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-${var.project_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"  # Secure back to ALB
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Secret header to prevent direct ALB access
    custom_header {
      name  = "X-Origin-Verify"
      value = var.origin_verify_header
    }
  }

  # ORIGIN 2: S3 (static assets)
  origin {
    domain_name = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id   = "S3-${var.project_name}-assets"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  # DEFAULT CACHE BEHAVIOR - ALB
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${var.project_name}"

    forwarded_values {
      query_string = true  # Forward query params
      cookies {
        forward = "all"  # Forward cookies (sessions)
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    
    # Don't cache dynamic content
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
    
    compress = true  # Gzip
  }

  # ORDERED CACHE BEHAVIOR - S3 ASSETS
  ordered_cache_behavior {
    path_pattern     = "/static/*"  # URLs starting with /static/
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.project_name}-assets"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"  # No cookies for static assets
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    
    # Aggressive caching for static assets
    min_ttl     = 86400     # 1 day
    default_ttl = 604800    # 1 week
    max_ttl     = 31536000  # 1 year
    
    compress = true
  }

  # SSL/TLS settings
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.main.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Geo restrictions (none for now)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # WAF integration
  web_acl_id = aws_wafv2_web_acl.main.arn

  tags = {
    Name = "${var.project_name}-cdn"
  }

  depends_on = [aws_acm_certificate_validation.main]
}