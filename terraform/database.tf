# --- Database Credentials ---
resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_secret" {
  name_prefix = "aurora-serverless-secret-"
  description = "Secret for Aurora DB"
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "postgres"
    password = random_password.db_password.result
  })
}

# --- Aurora Serverless v2 setup ---
resource "aws_db_subnet_group" "aurora_subnet" {
  name       = "aurora-subnet-group-demo"
  subnet_ids = data.aws_subnets.default.ids
  description = "Subnet group for Aurora Demo"
}

resource "aws_rds_cluster" "demo_cluster" {
  cluster_identifier      = "aurora-serverless-demo"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "16.6"
  database_name           = var.db_name
  master_username         = "postgres"
  master_password         = random_password.db_password.result
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet.name
  skip_final_snapshot     = true
  enable_http_endpoint    = true # This enables the Data API

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "demo_instance" {
  cluster_identifier = aws_rds_cluster.demo_cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.demo_cluster.engine
  engine_version     = aws_rds_cluster.demo_cluster.engine_version
}

# Run database table initialization and data seeding automatically
resource "null_resource" "db_initializer" {
  depends_on = [
    aws_rds_cluster_instance.demo_instance,
    aws_secretsmanager_secret_version.db_secret_val
  ]

  # Re-run this provisioner whenever the database cluster changes
  triggers = {
    cluster_id = aws_rds_cluster.demo_cluster.id
  }

  provisioner "local-exec" {
    command = "python3 -m venv .venv && .venv/bin/pip install boto3 && .venv/bin/python3 ${path.module}/../src/init_db.py ${aws_rds_cluster.demo_cluster.arn} ${aws_secretsmanager_secret.db_secret.arn}"
  }
}
