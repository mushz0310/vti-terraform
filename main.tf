# VPC
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = false
  enable_dns_hostnames = false

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# Subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.name_prefix}-public-subnet-01"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${var.name_prefix}-private-subnet-01"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# Route Tables
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rtb"
  }
}

resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-private-rtb"
  }
}

# Associate Route Tables
resource "aws_route_table_association" "public_rtb_a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "private_rtb_a" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rtb.id
}

# Security Groups
resource "aws_security_group" "public_sg" {
  name_prefix = "public-sg-"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.local_ip]
  }

  ingress {
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
    Name = "${var.name_prefix}-public-sg"
  }
}

resource "aws_security_group" "private_sg" {
  name_prefix = "private-sg-"
  description = "Allow SSH from public EC2"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_instance.public_ec2_01.public_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-private-sg"
  }
}

# SSH Key Pair
resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.name_prefix}-tf-key-pair"
  public_key = tls_private_key.key.public_key_openssh
}


# EC2 Instances
resource "aws_instance" "public_ec2_01" {
  ami             = data.aws_ami.ubuntu
  instance_type   = var.ec2_instance_type
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.public_sg.name]
  key_name        = aws_key_pair.key_pair.key_name

  tags = {
    Name = "${var.name_prefix}-public-ec2-01"
  }
}

resource "aws_instance" "private_ec2_01" {
  ami             = data.aws_ami.ubuntu
  instance_type   = var.ec2_instance_type
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.private_sg.name]
  key_name        = aws_key_pair.key_pair.key_name

  tags = {
    Name = "${var.name_prefix}-private-ec2-01"
  }
}
