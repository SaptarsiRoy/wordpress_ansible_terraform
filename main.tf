#getting id of default vpc
data "aws_vpc" "default_vpc" {
   default = true
}

#creating rds security group for connectivity
resource "aws_security_group" "rdssg" {
   name = "rdsdb"
   description = "allow mysql through firewall"
   vpc_id = data.aws_vpc.default_vpc.id

   ingress {
      description = "allow rds"
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      security_groups = ["wordpress"]
   }
   egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
   }
}

#creating security group for wordpress instance
resource "aws_security_group" "wpsg" {
   name = "wordpress"
   description = "allow ssh and http services through firewall"
   vpc_id = data.aws_vpc.default_vpc.id

   ingress {
      description = "allow ssh"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["49.37.19.254/32"]
   }

   ingress {
      description = "allow http"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
   }

   ingress {
      description = "allow rds to connect"
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      security_groups = ["rdssg"]
   }
   egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
   }

   tags = {
      Name = "wordpress"
   }
}

#module for creating RDS database
module "database" {
   source = "./modules/database/"

   admin_password = var.admin_password

   depends_on = [
      aws_security_group.rdssg,
      aws_security_group.wpsg,
   ]
}

#module for creating wordpress ec2 instance
module "instances" {
   source = "./modules/instances/"
   depends_on = [
      module.database,
      aws_security_group.rdssg,
      aws_security_group.wpsg
      ]
}

#creating variable file for ansible
resource "local_file" "vatiable-file" {
   content = <<EOT
   db_name: "wpdb"
   db_username: "admin"
   db_password: "${var.admin_password}
   db_endpoint: "${module.database.aws_db_instanace.endpoint}"
   EOT
   filename = "playbook/vars.yml"
}

resource "null_resource" "run-playbook" {
   provisioner "local-exec" {
   command = "chmod 400 playbook/mykey.pem &&  ansible-playbook playbook/playbook.yml --private-key playbook/mykey.pem -i playbook/ec2.py"
   }
}