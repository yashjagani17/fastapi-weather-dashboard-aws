output "primary_bucket_name" {
  value = aws_s3_bucket.primary.id
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.distribution.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.api.repository_url
}

output "alb_dns_name" {
    value = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.api.name
}