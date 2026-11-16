terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "devsecops" {
  key_name   = "devsecops-key"
  public_key = file(pathexpand(var.public_key_path))
}

resource "aws_security_group" "ci" {
  name        = "devsecops-ci-sg"
  description = "Jenkins, SonarQube and Grafana for my IP only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "devsecops-ci-sg" }
}

resource "aws_security_group" "k8s" {
  name        = "devsecops-k8s-sg"
  description = "k3s node: app NodePort and API server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description     = "Kubernetes API from the CI server only"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.ci.id]
  }

  ingress {
    description     = "App NodePort from me and from the CI server"
    from_port       = 30080
    to_port         = 30080
    protocol        = "tcp"
    cidr_blocks     = [var.my_ip_cidr]
    security_groups = [aws_security_group.ci.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "devsecops-k8s-sg" }
}

resource "aws_instance" "ci" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.ci_instance_type
  key_name                    = aws_key_pair.devsecops.key_name
  vpc_security_group_ids      = [aws_security_group.ci.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 25
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  tags = { Name = "devsecops-ci" }
}

resource "aws_instance" "k8s" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.k8s_instance_type
  key_name                    = aws_key_pair.devsecops.key_name
  vpc_security_group_ids      = [aws_security_group.k8s.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "devsecops-k8s" }
}
