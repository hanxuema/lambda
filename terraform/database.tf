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
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]

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

# --- VPC Endpoints & Security Groups for Direct Connection Demo ---

# Security Group for Lambda functions in the VPC
resource "aws_security_group" "lambda_sg" {
  name        = "aurora-demo-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Aurora RDS
resource "aws_security_group" "rds_sg" {
  name        = "aurora-demo-rds-sg"
  description = "Security group for Aurora cluster"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for VPC Endpoint
resource "aws_security_group" "vpce_sg" {
  name        = "aurora-demo-vpce-sg"
  description = "Security group for Secrets Manager VPC Endpoint"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# VPC Endpoint for Secrets Manager (allows Lambda in VPC to fetch secrets)
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.default.ids
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true
}
