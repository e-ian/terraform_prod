provider "aws" {
    region = "us-east-2"
}

resource "aws_db_instance" "mysqldb" {
    identifier_prefix = "terraform-stag"
    engine = "mysql"
    allocated_storage = 10
    instance_class = "db.t2.micro"
    username = "admin"

    # password = data.aws_secretsmanager_secret_version.db_password.secret_string
    password = "hshdywnq2*&^"
}

# to be configured later on AWS secrets manager console

# data "aws_secretsmanager_secret_version" "db_password" {
#     secret_id = "mysql-master-password-stage"
# }

terraform {
    backend "s3" {
        bucket = "terra-prod-state"
        key = "stage/datastores/mysql/terraform.tfstate"
        region = "us-east-2"

        dynamodb_table = "terraform-prod-locks"
        encrypt = true
    }
}