resource "aws_vpc" "vpc1" {
  cidr_block = "var.vpc1_cidr_block"
}

resource "aws_vpc" "vpc2" {
  cidr_block =" var.vpc2_cidr_block"
}


resource "aws_subnet" "frontend" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = "var.frontend_subnet_cidr_block"

  tags = {
    Name = "frontend"
  }
}

resource "aws_subnet" "backend" {
  vpc_id     = "${aws_vpc.vpc1.id}"
  cidr_block = " var.backend_subnet_cidr_block"

  tags = {
    Name = "backend"
  }
}


resource "aws_security_group" "frontend_nsg" {
  vpc_id = "${aws_vpc.vpc1.id}"

  dynamic "ingress" {
    for_each = "var.frontend_inbound_ports"
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}


resource "aws_security_group" "backend_nsg" {
  vpc_id = "${aws_vpc.vpc1.id}"

  dynamic "ingress" {
    for_each =" var.backend_inbound_ports"
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_subnet" "dmz_subnet" {
  vpc_id                  = "${aws_vpc.vpc2.id}"
  cidr_block              = "var.dmz_subnet_cidr_block"
}

resource "aws_subnet" "mgmt_subnet" {
  vpc_id                  = "${aws_vpc.vpc2.id}"
  cidr_block              = "var.mgmt_subnet_cidr_block"
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

  dynamic "ingress" {
    for_each = "var.mgmt_inbound_ports"
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}




resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id        = "${aws_vpc.vpc1.id}"
  peer_vpc_id   = aws_vpc.vpc2.id
  auto_accept   = true
}

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
