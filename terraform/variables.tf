variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "db_name" {
  description = "Name of the Aurora database"
  type        = string
  default     = "demodb"
}
