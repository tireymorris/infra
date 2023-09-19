resource "aws_ecs_task_definition" "frontend" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  family = "frontend"
  container_definitions = templatefile(
    "templates/frontend.tpl",
    {
      region       = var.region
      name         = "frontend"
      image        = aws_ecr_repository.frontend.repository_url
      command      = ["/docker-entrypoint-next.sh"]
      log_group    = aws_cloudwatch_log_group.frontend.name
      log_stream   = aws_cloudwatch_log_stream.frontend_web.name
      graphql_host = "https://${var.subdomain}.${var.domain}/graphql"
    }
  )
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.frontend_task.arn
}

resource "aws_ecs_service" "frontend" {
  name                               = "frontend"
  cluster                            = aws_ecs_cluster.prod.id
  task_definition                    = aws_ecs_task_definition.frontend.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.ecs_frontend.id]
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 3000
  }
}

resource "aws_security_group" "ecs_frontend" {
  name   = "ecs-frontend"
  vpc_id = aws_vpc.prod.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.frontend_lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "frontend_task" {
  name = "frontend-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = "FrontendECSExecution"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "frontend"
  retention_in_days = var.ecs_frontend_retention_days
}

resource "aws_cloudwatch_log_stream" "frontend_web" {
  name           = "frontend"
  log_group_name = aws_cloudwatch_log_group.frontend.name
}
