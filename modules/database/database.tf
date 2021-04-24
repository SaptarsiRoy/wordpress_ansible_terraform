resource "aws_security_group" "rdssg" {}

#creating rds database
resource "aws_db_instance" "wpdb" {
   allocated_storage = 10
   storage_type = "gp2"
   engine = "mysql"
   engine_version = "5.7"
   parameter_group_name = "default.mysql5.7"
   instance_class = "db.t2.micro"
   vpc_security_group_ids = [aws_security_group.rdssg.id]
   publicly_accessible    = true
   name = "wpdb"
   username = "admin"
   password = var.admin_password
   skip_final_snapshot  = true
   auto_minor_version_upgrade = true
   port = 3306
}