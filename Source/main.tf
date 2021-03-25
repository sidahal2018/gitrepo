data "aws_availability_zones" "available" {    # Get list of availability zones
state = "available"
}
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
resource "aws_subnet" "public" {
  count = var.required_number_of_publicsubnets == null ? length(data.aws_availability_zones.available.names) :var.required_number_of_publicsubnets
  cidr_block = cidrsubnet(var.vpc-cidr, 8, count.index)
  vpc_id = aws_vpc.myvpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "publicsubnet-${count.index+1}"
  }
}
# create private subnets
resource "aws_subnet" "private" {
  count = var.required_number_of_privatesubnets==null ? length(data.aws_availability_zones.available.names) : var.required_number_of_privatesubnets
  cidr_block = cidrsubnet(var.vpc-cidr, 8, count.index + 2)
  vpc_id = aws_vpc.myvpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags= {
    Name = "privatesubnet-${count.index+1}"
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
  subnet_id = element(aws_subnet.public.*.id, 0)

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
resource "aws_route_table_association" "publicsubnet" {
  count = var.required_number_of_publicsubnets==null ? length(data.aws_availability_zones.available.names) : var.required_number_of_publicsubnets
  subnet_id = element(aws_subnet.public.*.id,count.index)
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
resource "aws_route_table_association" "privatesubnet" {
  count = var.required_number_of_privatesubnets==null ? length(data.aws_availability_zones.available.names) : var.required_number_of_privatesubnets
  subnet_id = element(aws_subnet.private.*.id,count.index)
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
    cidr_blocks = ["71.173.193.5/32"]
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

  dynamic "ingress" {
  iterator = port
  for_each = var.ingressrules
  content {
   from_port = port.value
   to_port = port.value
   protocol = "tcp"
  security_groups = [aws_security_group.bastiontraffic.id, aws_security_group.sg.id]
  }
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
# create ec2-instance for Bastion Host
# lookup(map, key, [default]) - Performs a dynamic lookup into a map variable based on the region
resource "aws_instance" "bastion" {
  count = var.required_number_of_publicsubnets == null ? length(data.aws_availability_zones.available.names) :var.required_number_of_publicsubnets
  ami = lookup(var.ec2_ami, var.region)
  instance_type= var.instance_type
  subnet_id = element(aws_subnet.public.*.id, count.index)
  security_groups = [aws_security_group.bastiontraffic.id]
  key_name = aws_key_pair.keypair.key_name
  tags = {
    Name = "Bastion Host"
  }
}
resource "aws_instance" "web" {
  count = var.required_number_of_publicsubnets == null ? length(data.aws_availability_zones.available.names) :var.required_number_of_publicsubnets
  ami = lookup(var.ec2_ami, var.region)
  instance_type= var.instance_type
  subnet_id = element(aws_subnet.public.*.id, count.index)
  security_groups = [aws_security_group.webtraffic.id]
  user_data = file("script.sh")  # file function reads the scripts from the script.sh file 
  key_name = aws_key_pair.keypair.key_name
  tags = {
  Name = "Webserver-${count.index+1}"
  }
}
 resource "aws_instance" "db" {
  count = var.required_number_of_privatesubnets == null ? length(data.aws_availability_zones.available.names) : var.required_number_of_privatesubnets
  ami = lookup(var.ec2_ami, var.region)
  instance_type= var.instance_type
  key_name = aws_key_pair.keypair.key_name
  subnet_id = element(aws_subnet.private.*.id, count.index)
  security_groups = [aws_security_group.webtraffic.id]
  tags = {
  Name = "DBserver-${count.index+1}"
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
  subnets = [aws_subnet.public[0].id, aws_subnet.public[1].id]
  security_groups = [aws_security_group.sg.id]
  ip_address_type = "ipv4"
 tags = {
   name = "Application-Load-Balancer"
 }
}

resource "aws_lb_target_group_attachment" "ec2-attach1" {
  target_group_arn = aws_lb_target_group.target1.arn
  target_id = aws_instance.web[0].id
  port = 80
}

resource "aws_lb_target_group_attachment" "ec2-attach2" {
  target_group_arn = aws_lb_target_group.target2.arn
  target_id = aws_instance.web[1].id
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