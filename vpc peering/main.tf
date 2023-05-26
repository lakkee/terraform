resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_vpc" "vpc2" {
  cidr_block = "172.168.0.0/16"
}

resource "aws_subnet" "frontend" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "frontend"
  }
}

resource "aws_subnet" "backend" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "backend"
  }
}

resource "aws_security_group" "frontend_nsg" {
  vpc_id = "${aws_vpc.vpc1.id}"

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
  vpc_id ="${aws_vpc.vpc1.id}"

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_subnet" "dmz_subnet" {
  vpc_id                  = "${aws_vpc.vpc2.id}"
  cidr_block              = "172.168.1.0/24"
}

resource "aws_subnet" "mgmt_subnet" {
  vpc_id                  = "${aws_vpc.vpc2.id}"
  cidr_block              = "172.168.2.0/24"
}

resource "aws_security_group" "dmz_nsg" {

  vpc_id ="${aws_vpc.vpc2.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "mgmt_nsg" {

  vpc_id = "${aws_vpc.vpc2.id}"

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

resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id        = "${aws_vpc.vpc1.id}"
  peer_vpc_id   = aws_vpc.vpc2.id
  peer_region   = "us-east-1"
  auto_accept   = true
}

#resource "aws_route" "vpc1_peering_route" {
 # route_table_id            = aws_vpc.vpc1_route_table.id
  #destination_cidr_block    = aws_vpc.vpc2.cidr_block
#  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
#}

#resource "aws_route" "vpc2_peering_route" {
#  route_table_id            = aws_vpc.vpc2_route_table.id
 # destination_cidr_block    = aws_vpc.vpc1.cidr_block
 # vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
#}

resource "aws_instance" "frontend_instance" {
  ami           = "ami-0889a44b331db0194"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.frontend.id
  vpc_security_group_ids = [aws_security_group.frontend_nsg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              service nginx start
              EOF
}

resource "aws_instance" "backend_instance" {
  ami           = "ami-0889a44b331db0194"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.backend.id
  vpc_security_group_ids = [aws_security_group.backend_nsg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y mongodb
              service mongodb start
              EOF
}

resource "aws_instance" "bastion_server" {
  ami           = "ami-0889a44b331db0194"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.mgmt_subnet.id
  vpc_security_group_ids = [aws_security_group.mgmt_nsg.id]
  tags = {
    Name = "Bastion Server"
  }
}
