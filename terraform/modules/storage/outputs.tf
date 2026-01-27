output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.id
}

output "frontend_cloudfront_domain" {
  value = aws_cloudfront_distribution.frontend.domain_name
}
