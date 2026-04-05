output "frontend_url" {
  description = "The public web URL hosted on Amazon S3"
  value       = "http://${aws_s3_bucket_website_configuration.frontend_website.website_endpoint}"
}

output "api_gateway_base_url" {
  description = "The public root URL for the API Gateway"
  value       = aws_apigatewayv2_api.demo_api.api_endpoint
}

output "api_urls" {
  description = "List of all provisioned API endpoints"
  value = {
    list_companies  = "${aws_apigatewayv2_api.demo_api.api_endpoint}/companies"
    get_company     = "${aws_apigatewayv2_api.demo_api.api_endpoint}/companies/{id}"
    list_directors  = "${aws_apigatewayv2_api.demo_api.api_endpoint}/companies/{id}/directors"
    update_director = "${aws_apigatewayv2_api.demo_api.api_endpoint}/directors/{id}"
    list_all_directors = "${aws_apigatewayv2_api.demo_api.api_endpoint}/directors"
    get_director_profile = "${aws_apigatewayv2_api.demo_api.api_endpoint}/directors/profile/{name}"
  }
}

output "database_username" {
  description = "The Aurora database master username"
  value       = aws_rds_cluster.demo_cluster.master_username
}

output "database_password" {
  description = "The Aurora database master password"
  value       = aws_rds_cluster.demo_cluster.master_password
  sensitive   = true
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = data.aws_vpc.default.id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = data.aws_subnets.default.ids
}

output "rds_cluster_arn" {
  description = "The ARN of the Aurora RDS cluster"
  value       = aws_rds_cluster.demo_cluster.arn
}
