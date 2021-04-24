#creating wordpress instance
resource "aws_instance" "wordpress" {
   ami             = var.ami_id
   instance_type   = var.instance_type
   security_groups = ["wordpress"]
   key_name = "FlutterKey"

   tags = {
      Name = "wordpress"
   }
}