provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# IAM Role
resource "aws_iam_role" "atlantis_role" {
  name = "atlantis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.atlantis_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.atlantis_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "dynamodb_full_access" {
  role       = aws_iam_role.atlantis_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Security Group
resource "aws_security_group" "atlantis_sg" {
  name        = "atlantis-sg"
  description = "Allow inbound traffic on port 4141"

  ingress {
    from_port   = 4141
    to_port     = 4141
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "atlantis_td" {
  family                   = "atlantis-td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  task_role_arn            = aws_iam_role.atlantis_role.arn
  execution_role_arn       = aws_iam_role.atlantis_role.arn

  container_definitions = jsonencode([
    {
      name      = "atlantis-container"
      image     = "ghcr.io/runatlantis/atlantis:latest"
      essential = true
      portMappings = [
        {
          containerPort = 4141
          hostPort      = 4141
        }
      ]
      environment = [
        {
          name  = "ATLANTIS_GH_USER"
          value = var.atlantis_gh_user
        },
        {
          name  = "ATLANTIS_GH_TOKEN"
          value = var.atlantis_gh_token
        },
        {
          name  = "ATLANTIS_REPO_ALLOWLIST"
          value = var.atlantis_repo_allowlist
        }
      ]
    }
  ])
}

# ECS Cluster
resource "aws_ecs_cluster" "atlantis_cluster" {
  name = "atlantis-cluster"
}

# ECS Service
resource "aws_ecs_service" "atlantis_service" {
  name            = "atlantis-service"
  cluster         = aws_ecs_cluster.atlantis_cluster.id
  task_definition = aws_ecs_task_definition.atlantis_td.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.atlantis_sg.id]
    assign_public_ip = true
  }
}
