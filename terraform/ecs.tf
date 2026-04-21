# SSM
resource "aws_ssm_parameter" "weather_api_key" {
  name  = "/${var.project_name}/WEATHER_API_KEY"
  type  = "SecureString"
  value = var.weather_api_key 
}

# ECS TASK
resource "aws_ecs_task_definition" "api" {
  family                   = "fastapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "fastapi-container"
      image     = "${aws_ecr_repository.api.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      secrets = [
        {
            name = "WEATHER_API_KEY"
            valueFrom = aws_ssm_parameter.weather_api_key.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-api"
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS SERVICE
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-api"
  retention_in_days = 7
}

resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = aws_subnet.private[*].id 
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false 
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "fastapi-container"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]
}

# IAM ECS EXEC
resource "aws_iam_role" "ecs_exec_role" {
  name = "${var.project_name}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM ECS TASK 
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

# IAM ECS SSM
resource "aws_iam_role_policy" "ssm_read" {
  name = "allow-ssm-read"
  role = aws_iam_role.ecs_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ssm:GetParameters", "kms:Decrypt"]
        Effect   = "Allow"
        Resource = [aws_ssm_parameter.weather_api_key.arn] 
      }
    ]
  })
}