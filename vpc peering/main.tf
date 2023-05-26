resource "aws_instance" "my_vm" {
  ami                       = "ami-0889a44b331db0194"
  instance_type             = "t2.micro"

  tags = {
    Name = "My EC2 instance"
  }
}