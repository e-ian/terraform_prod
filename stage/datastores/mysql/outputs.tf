output "address" {
    value = aws_db_instance.mysqldb.address
    description = "Connect to the database at this point"
}

output "port" {
    value = aws_db_instance.mysqldb.port
    description = "The port the database is listening on"
}