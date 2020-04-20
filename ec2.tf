provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region  = "${var.region}"
}

resource "aws_instance" "web-server" {
  ami           = "ami-0323c3dd2da7fb37d"
  instance_type = "t2.micro"

  tags = {
      Name = "terraform-example"
  }
  
}