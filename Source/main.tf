provider "aws" {
  region = var.region
}
# create vpc 
resource "aws_vpc" "myvpc" {
  cidr_block = var.vpc-cidr
  tags = {
    Name = "my-vpc-01"
  }

}
 # create public subnets

resource "aws_subnet" "public1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.myvpc.id
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-1"
  }
}

resource "aws_subnet" "public2" {
  cidr_block = "10.0.3.0/24"
  vpc_id = aws_vpc.myvpc.id
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true
  tags= {
    Name = "Public-Subnet-2"
  }
}

# create private subnets
resource "aws_subnet" "private1" {
  cidr_block = "10.0.2.0/24"
  vpc_id = aws_vpc.myvpc.id
  availability_zone = "us-east-2a"
  tags= {
    Name = "Private-Subnet-1"
  }
}
resource "aws_subnet" "private2" {
  cidr_block = "10.0.4.0/24"
  vpc_id = aws_vpc.myvpc.id
  availability_zone = "us-east-2b"
  tags= {
    Name = "Private-Subnet-2"
  }
}

# create internet gateway
resource "aws_internet_gateway" "myigw" {
vpc_id = aws_vpc.myvpc.id
tags = {
  Name = "my-internet-get-way"
}
}

# create the NAT gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.elasticip.id
  subnet_id = aws_subnet.public1.id
tags = {
  Name= "NAT-gateway"
}
}
# create route public table

resource "aws_route_table" "public" {
 vpc_id = aws_vpc.myvpc.id
 route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.myigw.id
 }
 tags = {
   Name = "Public-RouteTable"
 }
}
# route table association with Public Subnets

resource "aws_route_table_association" "publicsubnet1" {
  subnet_id = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "publicsubnet2" {
  subnet_id = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}
# create private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "Private-Route-Table"
  }

}
# route table association with Private Subnets
resource "aws_route_table_association" "privatesubnet1" {
  subnet_id = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "privatesubnet2" {
  subnet_id = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}
# create  security groups
# ALB security group
resource "aws_security_group" "sg" {
  name = "Allow all traffic"
  vpc_id = aws_vpc.myvpc.id

  ingress {
   from_port = 80
   to_port = 80
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]

  }
  egress{
    from_port = 0
    to_port = 0
    protocol= "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "Load-Balancer-Security-Group"
  }
}
# create Bastion Host Security Group:
resource "aws_security_group" "bastiontraffic" {
  name = "Allow only my IP"
  vpc_id = aws_vpc.myvpc.id
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "Bastion-Security-Group"
  }
}
# Web server security group
resource "aws_security_group" "webtraffic" {
  name = "Allow Traffic from Load Balancer"
  vpc_id = aws_vpc.myvpc.id

  ingress {
   from_port = 80
   to_port = 80
   protocol = "tcp"
  security_groups = [aws_security_group.sg.id]

  }

# allow port 22 from bastion host
ingress {
   from_port = 22
   to_port = 22
   protocol = "tcp"
  security_groups = [aws_security_group.bastiontraffic.id]

  }
  egress{
    from_port = 0
    to_port = 0
    protocol= "-1"
    cidr_blocks = ["0.0.0.0/0"]


}
tags = {
  Name= "Webserver-Security-Group"
}
}
#  create Database security group
 resource "aws_security_group" "databasetraffic" {
   name = "allow traffic from webserver"
   vpc_id = aws_vpc.myvpc.id

   ingress {
     from_port = 80
     to_port = 80
     protocol = "tcp"
     security_groups = [aws_security_group.webtraffic.id]
   }
   ingress {
   from_port = 22
   to_port = 22
   protocol = "tcp"
  security_groups = [aws_security_group.bastiontraffic.id]
   }
    egress{
    from_port = 0
    to_port = 0
    protocol= "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
tags = {
  Name= "Database-Security-Group"
}
 }
 resource "aws_key_pair" "keypair" {
  key_name = "siki"
  public_key = file("c:/Users/Siki/.ssh/id_rsa.pub")

}

# create ec2-instances
# create instances for Bastion Host
resource "aws_instance" "bastion" {
  ami = "ami-08962a4068733a2b6"
  instance_type= "t2.micro"
  subnet_id = aws_subnet.public1.id
  availability_zone = "us-east-2a"
  security_groups = [aws_security_group.bastiontraffic.id]
  key_name = aws_key_pair.keypair.key_name
  tags = {
    Name = "Bastion Host"
  }
}

resource "aws_instance" "web1" {
  ami = "ami-08962a4068733a2b6"
  instance_type= "t2.micro"
  subnet_id = aws_subnet.public1.id
  availability_zone = "us-east-2a"
  security_groups = [aws_security_group.webtraffic.id]
  user_data = file("script.sh")  # file function reads the scripts from the script.sh file 
  key_name = aws_key_pair.keypair.key_name
  tags = {
    Name = "Webserver-1"
  }
}
  resource "aws_instance" "web2" {
  ami = "ami-08962a4068733a2b6"
  instance_type= "t2.micro"
  subnet_id = aws_subnet.public2.id
  key_name = aws_key_pair.keypair.key_name
  availability_zone = "us-east-2b"
  security_groups = [aws_security_group.webtraffic.id]
  user_data = file("data.sh")
  tags = {
    Name = "Webserver-2"
  }
  }
 resource "aws_instance" "db1" {
  ami = "ami-08962a4068733a2b6"
  instance_type= "t2.micro"
  key_name = aws_key_pair.keypair.key_name
  subnet_id = aws_subnet.private1.id
  availability_zone = "us-east-2a"
  security_groups = [aws_security_group.webtraffic.id]
  tags = {
    Name = "DB-Server-1"
  }
 }
 resource "aws_instance" "db2" {
  ami = "ami-08962a4068733a2b6"
  instance_type= "t2.micro"
  subnet_id = aws_subnet.private2.id
  key_name = aws_key_pair.keypair.key_name
  availability_zone = "us-east-2b"
  security_groups = [aws_security_group.webtraffic.id]
  tags = {
    Name = "DB-Server-2"
  }
 }
# create  Elastic IP
 resource "aws_eip" "elasticip" {
   tags = {
     Name = "ElasticIP"
   }
  
}
resource "aws_lb_target_group" "target1" {
  health_check {
    interval = 10
    path = "/images/index.html"
    protocol = "HTTP"
    timeout = 5 
    healthy_threshold = 5
    unhealthy_threshold = 2
  }
  name = "webserver-target-group-1"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_lb_target_group" "target2" {
  health_check {
    interval = 10
    path = "/data/index.html"
    protocol = "HTTP"
    timeout = 5 
    healthy_threshold = 5
    unhealthy_threshold = 2
  }
  name = "webserver-target-group-2"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = aws_vpc.myvpc.id
}
resource "aws_lb" "loadbalancer" {
  name = "ALB"
  internal = false
  load_balancer_type = "application"
  subnets = [aws_subnet.public1.id, aws_subnet.public2.id]
  security_groups = [aws_security_group.sg.id]
  ip_address_type = "ipv4"
 tags = {
   name = "Application-Load-Balancer"
 }
}

resource "aws_lb_target_group_attachment" "ec2-attach1" {
  target_group_arn = aws_lb_target_group.target1.arn
  target_id = aws_instance.web1.id
  port = 80
}

resource "aws_lb_target_group_attachment" "ec2-attach2" {
  target_group_arn = aws_lb_target_group.target2.arn
  target_id = aws_instance.web2.id
  port = 80
}
resource "aws_lb_listener" "mylistener1" {
  load_balancer_arn = aws_lb.loadbalancer.arn
   port = 80
   protocol = "HTTP"

   default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target1.arn
   }

}
resource "aws_alb_listener_rule" "listener_path_based" {
  listener_arn = aws_lb_listener.mylistener1.arn
  action {    
  type = "forward"    
  target_group_arn = aws_lb_target_group.target1.arn
    }   
 condition {
    path_pattern {
      values = ["/images/*"]
    }
  }
}

resource "aws_alb_listener_rule" "listener_path_data" {
  listener_arn = aws_lb_listener.mylistener1.arn
  action {    
  type = "forward"    
  target_group_arn = aws_lb_target_group.target2.arn
    }   
 condition {
    path_pattern {
      values = ["/data/*"]
    }
  }
}