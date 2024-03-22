# vars.tf

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
  default     = ["subnet-03ba3956b0eb27dba", "subnet-04b3ca0d715791122"]
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
  default     = ["subnet-04eff99a8e3e592a8", "subnet-03b1c240c7cb86e20"]
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
  default     = "nginxweb1x2x3x"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where resources will be created"
  default     = "vpc-0a6d4b089d3cfa391"
}
