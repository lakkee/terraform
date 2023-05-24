terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "vpc2" {
  cidr_block = "172.168.0.0/16"
}

resource "aws_subnet" "frontend" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "backend" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "frontend_nsg" {
  vpc_id = aws_vpc.vpc1.id

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
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet_network_acl_association" "frontend_nacl_association" {
  subnet_id          = aws_subnet.frontend.id
  network_acl_id     = aws_security_group.frontend_nsg.id
}

resource "aws_subnet_network_acl_association" "backend_nacl_association" {
  subnet_id          = aws_subnet.backend.id
  network_acl_id     = aws_security_group.backend_nsg.id
}



resource "aws_subnet" "dmz" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = "172.168.1.0/24"
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "mgmt" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = "172.168.2.0/24"
  availability_zone       = "us-east-1b"
}

resource "aws_security_group" "dmz_nsg" {
  vpc_id = aws_vpc.vpc2.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "mgmt_nsg" {
  vpc_id = aws_vpc.vpc2.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet_network_acl_association" "dmz_nacl_association" {
  subnet_id          = aws_subnet.dmz.id
  network_acl_id     = aws_security_group.dmz_nsg.id
}

resource "aws_subnet_network_acl_association" "mgmt_nacl_association" {
  subnet_id          = aws_subnet.mgmt.id
  network_acl_id     = aws_security_group.mgmt_nsg.id
}


resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id        = aws_vpc.vpc1.id
  peer_vpc_id   = aws_vpc.vpc2.id
  peer_region   = "us-east-1"
  auto_accept   = true
}

resource "aws_vpc_peering_connection_accepter" "vpc_peering_accepted" {
  provider      = aws.us-east-1
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  auto_accept               = true
}

resource "aws_instance" "web_application" {
  ami           = "ami-0889a44b331db0194"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.frontend.id
  vpc_security_group_ids = [aws_security_group.frontend_nsg.id]

}

resource "aws_db_instance" "database" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "password"
  subnet_group_name      = "backend"
  vpc_security_group_ids = [aws_security_group.backend_nsg.id]
}

resource "aws_instance" "jump_server" {
  ami           = "ami-0889a44b331db0194"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.mgmt.id
  vpc_security_group_ids = [aws_security_group.mgmt_nsg.id]

}
