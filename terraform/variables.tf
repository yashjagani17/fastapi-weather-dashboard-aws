variable "aws_region" {
  description = "primary AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Name of the project (used as prefix for services)"
  type        = string
  default     = "yash-owapi-dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use (must be at least 2)"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "weather_api_key" {
    description = "API key for openweatherAPI"
    type = string
    sensitive = true
}