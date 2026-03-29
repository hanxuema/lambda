# --- Lambda Common IAM Role ---
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_demo_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_data_api_policy" {
  name        = "lambda_data_api_policy"
  description = "Allow Lambda to access RDS Data API and Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction"
        ]
        Resource = aws_rds_cluster.demo_cluster.arn
      },
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.db_secret.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_data_api_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_data_api_policy.arn
}

# --- Package and Deploy Lambdas ---
locals {
  lambdas = {
    "list_companies"       = "list_companies.handler",
    "get_company"          = "get_company.handler",
    "list_directors"       = "list_directors.handler",
    "update_director"      = "update_director.handler",
    "list_all_directors"   = "list_all_directors.handler",
    "get_director_profile" = "get_director_profile.handler"
  }
}

data "archive_file" "lambda_zip" {
  for_each    = local.lambdas
  type        = "zip"
  output_path = "${path.module}/lambda_${each.key}.zip"

  source {
    content  = file("${path.module}/../src/${each.key}.py")
    filename = "${each.key}.py"
  }

  source {
    content  = file("${path.module}/../src/database.py")
    filename = "database.py"
  }
}

resource "aws_lambda_function" "api_lambda" {
  for_each         = local.lambdas
  function_name    = "demo_${each.key}"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = each.value
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip[each.key].output_path
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256

  environment {
    variables = {
      DB_SECRET_ARN  = aws_secretsmanager_secret.db_secret.arn
      DB_CLUSTER_ARN = aws_rds_cluster.demo_cluster.arn
      DB_NAME        = var.db_name
    }
  }
}
