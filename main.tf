provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "terra-prod" {
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"

    tags = {
        Name = "terraform-prod"
    }
}