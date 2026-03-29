resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "frontend" {
  bucket        = "demo-frontend-lambda-${random_string.bucket_suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend_access" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.frontend_access]
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  
  # Utilizes Terraform templatefile() to inject the dynamic API URL seamlessly into the HTML
  content      = templatefile("${path.module}/../frontend/index.html.tpl", {
    api_base_url = aws_apigatewayv2_api.demo_api.api_endpoint
  })
  
  content_type = "text/html"
  depends_on   = [aws_s3_bucket_policy.allow_public_read]
}
