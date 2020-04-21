provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region  = var.region
}

resource "aws_launch_configuration" "web-server" {
  image_id        = "ami-07ebfd5b3428b6f4d"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF 
    lifecycle {
      create_before_destroy = true 
    }

    
 
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}


resource "aws_autoscaling_group" "web-server"{
  launch_configuration = aws_launch_configuration.web-server.name  
  vpc_zone_identifier = data.aws_subnet_ids.default.ids 
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  min_size = 2
  max_size = 4

  tag {
    key = "name"
    value = "terraform-asg-web-server"
    propagate_at_launch = true
  }

}


resource "aws_lb" "web-server" {
  name = "terraform-asg-web-server"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids 
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  condition {
    field = "path-pattern"
    values = ["*"]
  }
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn 
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web-server.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"
  fixed_response {
    content_type = "text/plain"
    message_body = "404: page not found"
    status_code = 404
  }

  }
}



resource "aws_security_group" "alb" {
  name = "terraform-web-server-alb"

  #allow inbound HTTP requests 
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all outboundrequest 
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  
  }
}


resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-web-server"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id 

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval  = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
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




  output "alb_dns_name" {
     value = aws_lb.web-server.dns_name
     description = "The domain name of the load balancer"
 }
