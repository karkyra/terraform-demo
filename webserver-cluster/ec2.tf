provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region  = var.region
}

resource "aws_instance" "web-server" {
  ami           = "ami-07ebfd5b3428b6f4d"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF 

  tags = {
      Name = "terraform-example"
  }
  
 
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

  output "public_ip" {
     value = aws_instance.web-server.public_ip
     description = "The  public IP address of the web server"
 }
