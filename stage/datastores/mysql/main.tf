provider "aws" {
    region = "us-east-2"
}

resource "aws_db_instance" "mysqldb" {
    identifier_prefix = "terraform-stag"
    engine = "mysql"
    allocated_storage = 10
    instance_class = "db.t2.micro"
    name = "mysql_database"
    username = "admin"

    password = data.aws_secretmanager_secret_version.db_password.secret_string
}

data "aws_secretmanager_secret_version" "db_password" {
    secret_id = "mysql-master-password-stage"
}