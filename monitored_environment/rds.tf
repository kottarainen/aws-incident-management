resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "monitored_rds" {
  identifier        = "monitored-rds"
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  username          = "admin"
  password          = var.db_password
  skip_final_snapshot = true
  publicly_accessible = true

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.allow_rds.id]

  tags = {
    Environment = "Demo"
    Name        = "MonitoredRDS"
  }
}

resource "aws_security_group" "allow_rds" {
  name        = "allow-rds-access"
  description = "Allow inbound MySQL access"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Store DB identifier securely for lookup in Lambda
resource "aws_secretsmanager_secret" "rds_secret" {
  name = "rds-connectivity-config"
}

resource "aws_secretsmanager_secret_version" "rds_secret_value" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    db_instance_identifier = aws_db_instance.monitored_rds.id
    region                 = var.aws_region
  })
}
