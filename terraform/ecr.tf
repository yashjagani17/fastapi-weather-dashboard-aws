# ECR
resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api"
  force_delete         = true 
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}