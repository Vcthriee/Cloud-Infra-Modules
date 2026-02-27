
# WAF WEB ACL - WEB APPLICATION FIREWALL
# Protects against common attacks

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-waf"
  description = "WAF rules for ${var.project_name}"
  scope       = "CLOUDFRONT"  # Global scope for CloudFront

  # Default allow (block specific bad requests)
  default_action {
    allow {}
  }

  # RULE 1: AWS MANAGED RULES (OWASP TOP 10)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # RULE 2: RATE LIMITING
  rule {
    name     = "RateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000  # 2000 requests per 5 minutes
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf-metric"
    sampled_requests_enabled   = true
  }
}