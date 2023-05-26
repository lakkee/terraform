resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_vpc" "vpc2" {
  cidr_block = "172.168.0.0/16"
}

resource "aws_subnet" "frontend" {
  vpc_id     = aws_vpc.vpc1
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "frontend"
  }
}

resource "aws_subnet" "backend" {
  vpc_id     = aws_vpc.vpc1
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "backend"
  }
}

resource "aws_security_group" "frontend_nsg" {
  vpc_id = aws_vpc.vpc1

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_nsg" {
  vpc_id = aws_vpc.vpc1

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}