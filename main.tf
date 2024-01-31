provider "aws" {
    region = "us-east-2"
}

resource "aws_launch_configuration" "terra-prod" {
    image_id = "ami-0c55b159cbfafe1f0"
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

resource "aws_security_group" "instance" {
    name = "prod_sg"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_autoscaling_group" "terra-prod"{
    launch_configuration = aws_launch_configuration.terra-prod.name
    vpc_zone_identifier = data.aws_subnets.default.ids

    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value = "terraform-asg-prod"
        propagate_at_launch = true
    }

}

variable "server_port" {
  type        = number
  default     = 8080
  description = "The port the server will use for HTTP requests"
}

# output "public_ip" {
#   value       = aws_launch_configuration.terra-prod.public_ip
#   description = "The public ip address of the webserver"
# }

# create data source

data "aws_vpcs" "default" {
    filter {
        name = "isDefault"
        values = ["true"]
    }
}

data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpcs.default.ids[0]]
    }
}
