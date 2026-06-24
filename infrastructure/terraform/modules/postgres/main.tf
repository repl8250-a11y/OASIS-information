// terraform module for postgres (AWS RDS example)

variable "name" {
  type = string
}

variable "engine" {
  type    = string
  default = "postgres"
}

variable "engine_version" {
  type    = string
  default = "16"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "storage_gb" {
  type    = number
  default = 20
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "publicly_accessible" {
  type    = bool
  default = false
}

# AWS provider must be configured by caller
resource "aws_db_instance" "postgres" {
  identifier              = var.name
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  storage_type            = "gp3"
  username                = var.master_username
  password                = var.master_password
  backup_retention_period = var.backup_retention_period
  multi_az                = var.multi_az
  publicly_accessible     = var.publicly_accessible
  skip_final_snapshot     = true
  apply_immediately       = false
  tags = {
    Name = var.name
  }
}

output "endpoint" {
  value = aws_db_instance.postgres.endpoint
}
