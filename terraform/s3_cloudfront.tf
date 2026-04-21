data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "random_password" "custom_header" {
  length  = 32
  special = false
}

# S3 PRIMARY
resource "aws_s3_bucket" "primary" {
  bucket = "${var.project_name}-primary"
  force_destroy = true
  tags   = { Name = "primary bucket", Environment = "dev" }
}

# S3 SECONDARY
resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary 
  bucket   = "${var.project_name}-secondary"
  force_destroy = true
  tags     = { Name = "secondary bucket", Environment = "dev" }
}

# VERSIONING
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  versioning_configuration { status = "Enabled" }
}

# CLOUDFRONT OAC
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CLOUDFRONT DISTRIBUTION
resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases = ["yashjagani.com", "www.yashjagani.com"]

  origin {
    domain_name              = aws_s3_bucket.primary.bucket_regional_domain_name
    origin_id                = "S3-primary"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  origin {
    domain_name              = aws_s3_bucket.secondary.bucket_regional_domain_name
    origin_id                = "S3-secondary"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  origin {
    domain_name = "api.yashjagani.com"
    origin_id   = "ALB-backend"

    custom_header {
      name  = "X-Custom-Header"
      value = random_password.custom_header.result
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin_group {
    origin_id = "S3-origin"
    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }
    member { origin_id = "S3-primary" }
    member { origin_id = "S3-secondary" }
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "ALB-backend"

    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]

    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" 
    
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-origin"

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.us.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# BUCKET POLICIES
resource "aws_s3_bucket_policy" "primary" {
  bucket = aws_s3_bucket.primary.id
  policy = data.aws_iam_policy_document.s3_policy_primary.json
}

resource "aws_s3_bucket_policy" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  policy   = data.aws_iam_policy_document.s3_policy_secondary.json
}

# IAM POLICY DOCUMENTS
data "aws_iam_policy_document" "s3_policy_primary" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.primary.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }
}

data "aws_iam_policy_document" "s3_policy_secondary" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.secondary.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }
}

# REPLICATION ROLE & POLICIES
resource "aws_iam_role" "replication" {
  name = "s3-replication-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "replication" {
  name = "s3-replication-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Effect   = "Allow"
        Resource = [aws_s3_bucket.primary.arn]
      },
      {
        Action   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.primary.arn}/*"]
      },
      {
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.secondary.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# REPLICATION
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.secondary
  ]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "full-bucket-replication"
    status = "Enabled"
    
    destination {
      bucket        = aws_s3_bucket.secondary.arn
      storage_class = "STANDARD"
    }
  }
}