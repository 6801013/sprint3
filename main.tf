# -------------------------
# Provider
# -------------------------
provider "aws" {
  region = "ap-northeast-1"
}

# -------------------------
# Variables
# -------------------------
variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0bc8f29a8fc3184aa"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/21"
}

variable "web_cidr" {
  description = "CIDR block for web subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "api_cidr_1" {
  description = "CIDR block for api subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "api_cidr_2" {
  description = "CIDR block for api subnet 2"
  type        = string
  default     = "10.0.4.0/24"
}

variable "db_cidr_1" {
  description = "CIDR block for db subnet 1"
  type        = string
  default     = "10.0.2.0/24"
}

variable "db_cidr_2" {
  description = "CIDR block for db subnet 2"
  type        = string
  default     = "10.0.3.0/24"
}

variable "elb_cidr_1" {
  description = "CIDR block for ELB subnet 1"
  type        = string
  default     = "10.0.5.0/24"
}

variable "elb_cidr_2" {
  description = "CIDR block for ELB subnet 2"
  type        = string
  default     = "10.0.6.0/24"
}

variable "myip" {
  description = "Your IP address for restricted access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Key pair name for EC2 instances"
  type        = string
  default     = "test-ec2-key"
}

variable "web_name" {
  description = "Name prefix for web resources"
  type        = string
  default     = "web"
}

variable "api_name" {
  description = "Name prefix for api resources"
  type        = string
  default     = "api"
}

variable "db_name" {
  description = "Name prefix for db resources"
  type        = string
  default     = "db"
}

variable "main_name" {
  description = "Name prefix for main resources"
  type        = string
  default     = "main"
}

variable "elb_name" {
  description = "Name prefix for ELB resources"
  type        = string
  default     = "elb"
}

variable "api_az_1" {
  description = "AZ for api subnet 1"
  type        = string
  default     = "ap-northeast-1a"
}

variable "api_az_2" {
  description = "AZ for api subnet 2"
  type        = string
  default     = "ap-northeast-1c"
}

variable "elb_az_1" {
  description = "AZ for ELB subnet 1"
  type        = string
  default     = "ap-northeast-1a"
}

variable "elb_az_2" {
  description = "AZ for ELB subnet 2"
  type        = string
  default     = "ap-northeast-1c"
}

# -------------------------
# VPC and Networking
# -------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.main_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.main_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.main_name}-public-rt"
  }
}

resource "aws_subnet" "web_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.web_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.web_name}-subnet"
  }
}

resource "aws_subnet" "api_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.api_cidr_1
  availability_zone       = var.api_az_1
  map_public_ip_on_launch = true
  tags = { Name = "${var.api_name}-subnet-1" }
}


resource "aws_subnet" "api_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.api_cidr_2
  availability_zone       = var.api_az_2
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.api_name}-subnet-2"
  }
}

resource "aws_route_table_association" "api_assoc_2" {
  subnet_id      = aws_subnet.api_subnet_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "db_subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.db_cidr_1
  availability_zone = "ap-northeast-1a" # 異なるAZにする
  tags = {
    Name = "${var.db_name}-subnet-1"
  }
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.db_cidr_2
  availability_zone = "ap-northeast-1c" # 異なるAZにする
  tags = {
    Name = "${var.db_name}-subnet-2"
  }
}

resource "aws_route_table_association" "web_assoc" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "api_assoc" {
  subnet_id      = aws_subnet.api_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "elb_subnet_01" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.elb_cidr_1
  availability_zone       = var.elb_az_1
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.elb_name}-subnet-01"
  }
}

resource "aws_subnet" "elb_subnet_02" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.elb_cidr_2
  availability_zone       = var.elb_az_2
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.elb_name}-subnet-02"
  }
}

resource "aws_route_table_association" "elb_subnet_01_assoc" {
  subnet_id      = aws_subnet.elb_subnet_01.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "elb_subnet_02_assoc" {
  subnet_id      = aws_subnet.elb_subnet_02.id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Security Groups
# -------------------------
resource "aws_security_group" "web_sg" {
  name        = "${var.web_name}-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.web_name}-sg"
  }
}

resource "aws_security_group" "api_sg" {
  name        = "${var.api_name}-sg"
  description = "Allow HTTP from ALB and SSH from my IP"
  vpc_id      = aws_vpc.main.id

  # SSHは自分のIPだけ
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.myip]   
  }

  # HTTPはALBのSGからのみ
  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.api_name}-sg" }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.db_name}-sg"
  description = "Allow MySQL from API SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.api_sg.id]  # ← ここを置き換え
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.db_name}-sg" }
}

# -------------------------
# EC2 Instances
# -------------------------
resource "aws_instance" "web_ec2" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.web_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name      = var.key_name
  tags = {
    Name = "${var.web_name}-server"
  }
}

resource "aws_instance" "api_ec2" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.api_subnet.id
  vpc_security_group_ids = [aws_security_group.api_sg.id]
  key_name      = var.key_name
  tags = {
    Name = "${var.api_name}-server-1"
  }
}

resource "aws_instance" "api_ec2_2" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.api_subnet_2.id
  vpc_security_group_ids = [aws_security_group.api_sg.id]
  key_name      = var.key_name
  tags = {
    Name = "${var.api_name}-server-2"
  }
}


resource "aws_security_group" "alb_sg" {
  name        = "${var.elb_name}-sg"
  description = "Allow HTTP from Internet to ALB"
  vpc_id      = aws_vpc.main.id

  # 80番を全世界から（学習用）※本番はWAFやCIDR制限検討
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.elb_name}-sg" }
}

# -------------------------
# RDS
# -------------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
  tags = {
    Name = "${var.db_name}-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier                  = "${var.db_name}-server"
  engine                      = "mysql"
  engine_version              = "8.0"            # 明示推奨
  instance_class              = "db.t3.micro"
  allocated_storage           = 20

  username                    = "admin"          # ← ユーザー名はOK
  manage_master_user_password = true             # ← シークレットマネージャー用
  # master_user_secret_kms_key_id = "<KMSキーARN>"  # 任意：専用KMSを使うなら

  skip_final_snapshot         = true
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.db_sg.id]

  publicly_accessible         = false            # 直アクセス禁止（踏み台経由）
  storage_encrypted           = true             # ストレージの暗号化（最初しかできない）
  deletion_protection         = false            # 削除防止用、学習中はfalseでOK（実運用はtrue推奨）

  tags = { Name = "${var.db_name}-rds" }
}

# 便利：Secrets ManagerのARNを出力（中身は出さない）→これを使えば、AWS CLIやSDKでどのシークレットを取得するか指定できる。
output "rds_master_secret_arn" {
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
  description = "ARN of the RDS master user secret in Secrets Manager"
}

# 便利：RDSエンドポイントも出力→ MySQLクライアントやアプリの接続設定に必要
output "rds_endpoint" {
  value       = aws_db_instance.mysql.address
  description = "RDS endpoint hostname"
}

# -------------------------
# ALB / Target Group / Listener
# -------------------------

# Target Group（API EC2を登録、HTTP:80）
resource "aws_lb_target_group" "api_tg" {
  name     = "${var.api_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "${var.api_name}-tg" }
}

# ALB 本体（インターネット向け、ELB用サブネット2つに配置）
resource "aws_lb" "api_alb" {
  name               = "${var.api_name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.elb_subnet_01.id,
    aws_subnet.elb_subnet_02.id
  ]

  tags = { Name = "${var.api_name}-alb" }
}

# Listener :80 → Target Groupへフォワード
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}

# TGに2台目を登録
resource "aws_lb_target_group_attachment" "api2" {
  target_group_arn = aws_lb_target_group.api_tg.arn
  target_id        = aws_instance.api_ec2_2.id
  port             = 80
}

# 便利：ALBのDNS名を出力
output "alb_dns_name" {
  value       = aws_lb.api_alb.dns_name
  description = "Public DNS name of the API ALB"
}