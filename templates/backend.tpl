[
  {
    "name": "${name}",
    "image": "${image}",
    "essential": true,
    "links": [],
    "environment": [
      {
        "name": "DATABASE_URL",
        "value": "postgres://${rds_username}:${rds_password}@${rds_hostname}:5432/${rds_db_name}"
      },
    ],
    "portMappings": [
      {
        "containerPort": 8000,
        "hostPort": 8000,
        "protocol": "tcp"
      }
    ],
    "command": ${jsonencode(command)},
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "${log_stream}"
      }
    }
  }
]
