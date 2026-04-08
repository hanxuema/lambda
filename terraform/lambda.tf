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

# Allow Lambda to attach ENIs in VPC for `list_directors`
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "lambda_data_api_policy" {
  name        = "lambda_data_api_policy"
  description = "Allow Lambda to access RDS Data API and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction"
        ]
        Resource = aws_rds_cluster.demo_cluster.arn
      },
      {
        Effect = "Allow"
        Action = [
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

# --- Lambda Layer for Database Dependencies (pg8000) ---
data "archive_file" "db_layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/layer_pkg"
  output_path = "${path.module}/lambda_layer_db.zip"
}

resource "aws_lambda_layer_version" "db_layer" {
  filename            = data.archive_file.db_layer_zip.output_path
  layer_name          = "aurora_db_dependencies"
  compatible_runtimes = ["python3.12"]
  source_code_hash    = data.archive_file.db_layer_zip.output_base64sha256
}

# --- Special Lambda: list_directors (Traditional VPC Connection) ---
data "archive_file" "list_directors_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_list_directors.zip"
  source {
    content  = file("${path.module}/../src/list_directors.py")
    filename = "list_directors.py"
  }
  source {
    content  = file("${path.module}/../src/database.py")
    filename = "database.py"
  }
}

resource "aws_lambda_function" "api_lambda_traditional" {
  function_name    = "demo_list_directors"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "list_directors.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.list_directors_zip.output_path
  source_code_hash = data.archive_file.list_directors_zip.output_base64sha256

  # Crucial: Attaches Lambda to VPC Subnets
  vpc_config {
    subnet_ids         = data.aws_subnets.default.ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  layers = [aws_lambda_layer_version.db_layer.arn]

  environment {
    variables = {
      DB_SECRET_ARN = aws_secretsmanager_secret.db_secret.arn
      DB_ENDPOINT   = aws_rds_cluster.demo_cluster.endpoint
      DB_NAME       = var.db_name
    }
  }
}

# --- Special Lambda: get_company (RDS Proxy Connection) ---
data "archive_file" "get_company_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_get_company.zip"
  source {
    content  = file("${path.module}/../src/get_company.py")
    filename = "get_company.py"
  }
  source {
    content  = file("${path.module}/../src/database.py")
    filename = "database.py"
  }
}

resource "aws_lambda_function" "api_lambda_proxy" {
  function_name    = "demo_get_company"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "get_company.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.get_company_zip.output_path
  source_code_hash = data.archive_file.get_company_zip.output_base64sha256

  # Attaches Lambda to VPC Subnets
  vpc_config {
    subnet_ids         = data.aws_subnets.default.ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  layers = [aws_lambda_layer_version.db_layer.arn]

  environment {
    variables = {
      DB_SECRET_ARN  = aws_secretsmanager_secret.db_secret.arn
      PROXY_ENDPOINT = aws_db_proxy.demo_proxy.endpoint
      DB_NAME        = var.db_name
    }
  }
}
