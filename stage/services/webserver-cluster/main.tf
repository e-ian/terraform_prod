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

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB" # more robust check compared to EC2 type

    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value = "terraform-asg-prod"
        propagate_at_launch = true
    }

}


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

# create an application load balancer (ALB) using aws_lb resource
resource "aws_lb" "terra-prod" {
    name = "terraform-asg-prod"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb.id]
}

# define a listener for the ALB using the aws_lb_listener
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.terra-prod.arn
    port = 80
    protocol = "HTTP"
    # By default, return a simple 404 page
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }

    }
}

#create a security group for the ALB to allow incoming and outgoing traffic

resource "aws_security_group" "alb" {
    name = "terraform-prod-alb"

    # Allow inbound HTTP requests
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # Allow all outbound requests
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# create a target group for ASG using aws_lb_target_group resource

resource "aws_lb_target_group" "asg" {
    name = "terraform-asg-prod"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpcs.default.ids[0]

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

# create listener rules using the aws_lb_listener_rule resource
# adds a listener rule that sends requests that match any path to the target group
# that contains your ASG

resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
            values = ["*"]
        }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}

terraform {
    backend "s3" {
      key = "stage/services/webserver-cluster/terraform.tfstate"
    }
    
}

# read data from datastores/mysql/terraform.tfstate
data "terraform_remote_state" "db" {
    backend = "s3"

    config = {
        bucket = "terra-prod-state"
        key = "stage/datastores/mysql/terraform.tfstate"
    }
}
