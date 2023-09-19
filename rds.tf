resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_db_instance" "rds" {
  identifier                   = "${var.project_name}-rds"
  allocated_storage            = 20
  storage_type                 = "gp2"
  engine                       = "postgres"
  engine_version               = "15"
  instance_class               = "db.t3.micro"
  username                     = var.rds_username
  password                     = var.rds_password
  vpc_security_group_ids       = [aws_security_group.ecs_backend.id]
  db_subnet_group_name         = aws_db_subnet_group.rds.name
  parameter_group_name         = "default.postgres15"
  backup_retention_period      = 7
  deletion_protection          = true
  skip_final_snapshot          = true
  publicly_accessible          = false
  apply_immediately            = true
  multi_az                     = false
  performance_insights_enabled = false
  tags = {
    Name = "RDS Instance"
  }
}
