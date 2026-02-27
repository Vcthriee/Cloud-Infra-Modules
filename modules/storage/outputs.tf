
output "logs_bucket_id" {
  description = "S3 bucket ID for ALB logs"
  value       = aws_s3_bucket.logs.id
}

output "assets_bucket_id" {
  description = "S3 bucket ID for static assets"
  value       = aws_s3_bucket.assets.id
}

output "certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS"
  value       = aws_acm_certificate.main.arn
}

#output "cloudfront_domain_name" {
  #description = "CloudFront distribution domain name"
 # value       = aws_cloudfront_distribution.main.domain_name
#}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = aws_cloudfront_distribution.main.id
}