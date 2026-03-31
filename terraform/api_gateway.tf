# --- API Gateway (HTTP API) ---
resource "aws_apigatewayv2_api" "demo_api" {
  name          = "demo-apigw"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "PUT", "OPTIONS", "POST", "DELETE"]
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "demo_stage" {
  api_id      = aws_apigatewayv2_api.demo_api.id
  name        = "$default"
  auto_deploy = true
}

locals {
  routes = {
    "GET /companies"               = aws_lambda_function.api_lambda["list_companies"].arn
    "GET /companies/{id}"          = aws_lambda_function.api_lambda["get_company"].arn
    "GET /companies/{id}/directors" = aws_lambda_function.api_lambda_traditional.arn
    "PUT /directors/{id}"          = aws_lambda_function.api_lambda["update_director"].arn
    "GET /directors"               = aws_lambda_function.api_lambda["list_all_directors"].arn
    "GET /directors/profile/{name}" = aws_lambda_function.api_lambda["get_director_profile"].arn
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  for_each = local.routes
  
  api_id             = aws_apigatewayv2_api.demo_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = each.value
  integration_method = "POST" 
}

resource "aws_apigatewayv2_route" "api_route" {
  for_each = local.routes
  
  api_id    = aws_apigatewayv2_api.demo_api.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration[each.key].id}"
}

resource "aws_lambda_permission" "api_gw_invoke" {
  for_each      = local.lambdas
  
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.demo_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_invoke_traditional" {
  statement_id  = "AllowExecutionFromAPIGatewayTraditional"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda_traditional.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.demo_api.execution_arn}/*/*"
}
