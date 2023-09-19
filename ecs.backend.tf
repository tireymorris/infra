resource "aws_ecs_cluster" "prod" {
  name = "prod"
}

resource "aws_ecs_task_definition" "backend" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  family = "backend"
  container_definitions = templatefile(
    "templates/backend.tpl",
    {
      region        = var.region
      name          = "backend"
      image         = aws_ecr_repository.backend.repository_url
      command       = ["/docker-entrypoint-django.sh"]
      log_group     = aws_cloudwatch_log_group.backend.name
      log_stream    = aws_cloudwatch_log_stream.backend.name
      rds_db_name   = var.project_name
      rds_username  = var.rds_username
      rds_password  = var.rds_password
      rds_hostname  = aws_db_instance.rds.address
      allowed_hosts = "http://0.0.0.0:8000,https://${var.subdomain}.${var.domain},${var.subdomain}.${var.domain}"
      redis_url     = "redis://${aws_sqs_queue.celery_broker.id}:6379"
    },
  )
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.backend_task.arn
}

resource "aws_ecs_service" "backend" {
  name                               = "backend"
  cluster                            = aws_ecs_cluster.prod.id
  task_definition                    = aws_ecs_task_definition.backend.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8000
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_backend.id]
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    assign_public_ip = false
  }
}

resource "aws_security_group" "ecs_backend" {
  name   = "ecs-backend"
  vpc_id = aws_vpc.prod.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.frontend_lb.id, aws_security_group.ecs_frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "backend_task" {
  name = "backend-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = "BackendECSExecution"
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_access_policy" {
  name        = "ecr-access-policy"
  description = "Allows access to retrieve ECR authorization tokens"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_access_policy_attachment" {
  role       = aws_iam_role.backend_task.name
  policy_arn = aws_iam_policy.ecr_access_policy.arn
}

resource "aws_iam_policy" "rds_access_policy" {
  name        = "rds-access-policy"
  description = "Allows access to RDS resources"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds-db:connect",
          "rds:DescribeDBInstances",
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_access_policy_attachment" {
  policy_arn = aws_iam_policy.rds_access_policy.arn
  role       = aws_iam_role.backend_task.name
}

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name        = "cloudwatch-logs-policy"
  description = "Allows access to all CloudWatch Logs actions on any resource"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ],
        Resource = "*",
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.backend_task.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-backend-task-execution"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = "sts:AssumeRole",
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          },
          Effect = "Allow",
          Sid    = "AmazonECSTaskExecution"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "backend"
  retention_in_days = var.ecs_backend_retention_days
}

resource "aws_cloudwatch_log_stream" "backend" {
  name           = "backend"
  log_group_name = aws_cloudwatch_log_group.backend.name
}
