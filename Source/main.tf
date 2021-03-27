data "aws_availability_zones" "available" {    # Get list of availability zones
state = "available"
}
provider "aws" {
  region = var.region
}
resource "aws_vpc" "myvpc" {              # create vpc 
  cidr_block = var.vpc-cidr
  tags = {
    Name = var.vpc_name
  }
}
resource "aws_subnet" "public" {           # create public subnets
  count = var.required_number_of_publicsubnets == null ? length(data.aws_availability_zones.available.names) :var.required_number_of_publicsubnets
  cidr_block = cidrsubnet(var.vpc-cidr, 8, count.index)
  vpc_id = aws_vpc.myvpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "publicsubnet-${count.index+1}"
  }
}
resource "aws_subnet" "private" {                # create private subnets
  count = var.required_number_of_privatesubnets==null ? length(data.aws_availability_zones.available.names) : var.required_number_of_privatesubnets
  cidr_block = cidrsubnet(var.vpc-cidr, 8, count.index + 2)
  vpc_id = aws_vpc.myvpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags= {
    Name = "privatesubnet-${count.index+1}"
  }
}
resource "aws_internet_gateway" "myigw" {             # create internet gateway
vpc_id = aws_vpc.myvpc.id   
tags = {
  Name = var.internet_gateway_name
}
}
resource "aws_nat_gateway" "nat" {                      # create the NAT gateway
  allocation_id = aws_eip.elasticip.id
  subnet_id = element(aws_subnet.public.*.id, 0)
tags = {
  Name= var.nat_gateway_name
}
}
resource "aws_route_table" "public" {                    # create route public table
 vpc_id = aws_vpc.myvpc.id
 route {
  cidr_block = var.cidr_route-table
  gateway_id = aws_internet_gateway.myigw.id
 }
 tags = {
   Name = var.public_route_table_name
 }
}
resource "aws_route_table_association" "publicsubnet" {                  # route table association with Public Subnets
  count = var.required_number_of_publicsubnets==null ? length(data.aws_availability_zones.available.names) : var.required_number_of_publicsubnets
  subnet_id = element(aws_subnet.public.*.id,count.index)
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private" {                         # create private route table
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = var.cidr_route-table
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = var.private_route_table_name
  }
}
resource "aws_route_table_association" "privatesubnet" {            # route table association with Private Subnets
  count = var.required_number_of_privatesubnets==null ? length(data.aws_availability_zones.available.names) : var.required_number_of_privatesubnets
  subnet_id = element(aws_subnet.private.*.id,count.index)
  route_table_id = aws_route_table.private.id
}
resource "aws_security_group" "lb_security_groups" {
  vpc_id = aws_vpc.myvpc.id
  dynamic "ingress"{
  for_each = var.ingress_rules_lb
  content {
  from_port         = ingress.value.from_port
  to_port           = ingress.value.to_port
  protocol          = ingress.value.protocol
  description       = ingress.value.description
  cidr_blocks       = var.cidr_all_traffic
  }
  }
   dynamic "egress"{
  for_each = var.egressrules
    content {
    from_port = egress.value
    to_port = egress.value
    protocol= var.egress-rule-protocol
    cidr_blocks = var.egress_cidr_blocks
    }
   }
  tags ={
    Name = var.lb_sg_name
  }
}
resource "aws_security_group" "bastion_security_groups" {
vpc_id = aws_vpc.myvpc.id
  dynamic "ingress"{
  for_each = var.ingress_rules_bastion
  content {
  from_port         = ingress.value.from_port
  to_port           = ingress.value.to_port
  protocol          = ingress.value.protocol
  description       = ingress.value.description
  cidr_blocks       = var.allow_myip
  }
  }
   dynamic "egress"{
  for_each = var.egressrules
    content {
    from_port = egress.value
    to_port = egress.value
    protocol= var.egress-rule-protocol
    cidr_blocks = var.egress_cidr_blocks
    }
  }
  tags ={
    Name = var.bastion_sg_name
  }
}
resource "aws_security_group" "webtraffic" {
  vpc_id = aws_vpc.myvpc.id
  dynamic "ingress" {
  iterator = port
  for_each = var.ingressrules
  content {
   from_port = port.value
   to_port = port.value
   protocol = var.sg-protocol
  security_groups = [aws_security_group.bastion_security_groups.id, aws_security_group.lb_security_groups.id]
  }
  }
  dynamic "egress"{
  iterator = port
  for_each = var.egressrules
    content {
    from_port = port.value
    to_port = port.value
    protocol= var.egress-rule-protocol
    cidr_blocks = var.egress_cidr_blocks
    }
  }
  tags = {
    Name = var.webserver_sg_name
  }
}
 resource "aws_security_group" "databasetraffic" {
   vpc_id = aws_vpc.myvpc.id
  dynamic "ingress" {
  iterator = port
  for_each = var.ingressrules
  content {
     from_port = port.value
     to_port = port.value
     protocol = var.sg-protocol
    security_groups = [aws_security_group.webtraffic.id, aws_security_group.bastion_security_groups.id]
   }
  }
   dynamic "egress"{
  iterator = port
  for_each = var.egressrules
    content {
    from_port = port.value
    to_port = port.value
    protocol= var.egress-rule-protocol
    cidr_blocks = var.egress_cidr_blocks
    }
  }
  tags = {
    Name = var.DB_sg_name
  }
}
 resource "aws_key_pair" "keypair" {
  key_name = var.my_key_pair_name
  public_key = file("c:/Users/Siki/.ssh/id_rsa.pub")
}
resource "aws_instance" "bastion" {  # lookup(map, key, [default]) - Performs a dynamic lookup into a map variable based on the region
  count = var.required_number_of_publicsubnets == null ? length(data.aws_availability_zones.available.names) :var.required_number_of_publicsubnets
  ami = lookup(var.ec2_ami, var.region)
  instance_type= var.instance_type
  subnet_id = element(aws_subnet.public.*.id, count.index)
  security_groups = [aws_security_group.bastion_security_groups.id]
  key_name = aws_key_pair.keypair.key_name
  tags = {
    Name = var.Bastion_name
  }
}
resource "aws_instance" "web" {
  count = var.required_number_of_publicsubnets == null ? length(data.aws_availability_zones.available.names) :var.required_number_of_publicsubnets
  ami = lookup(var.ec2_ami, var.region)
  instance_type= var.instance_type
  subnet_id = element(aws_subnet.public.*.id, count.index)
  security_groups = [aws_security_group.bastion_security_groups.id]
  user_data = file("script.sh")                         # file function reads the scripts from the script.sh file 
  key_name = aws_key_pair.keypair.key_name
  tags = {
  Name = "Webserver-${count.index+1}"
  }
}
 resource "aws_instance" "db" {
  count = var.required_number_of_privatesubnets == null ? length(data.aws_availability_zones.available.names) : var.required_number_of_privatesubnets
  ami = lookup(var.ec2_ami, var.region)
  instance_type= var.instance_type
  subnet_id = element(aws_subnet.private.*.id, count.index)
  security_groups = [aws_security_group.webtraffic.id]
   key_name = aws_key_pair.keypair.key_name
  tags = {
  Name = "DBserver-${count.index+1}"
  }
 }
 resource "aws_eip" "elasticip" {                    # create  Elastic IP
   tags = {
     Name = var.Elastic_name
   }
}
resource "aws_lb_target_group" "target1" {
  health_check {
    interval = var. health_check_interval
    path = var.health_check_path[0]
    protocol = var.target_group_protocol
    timeout = var.health_check_timeout
    healthy_threshold = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }
  name = var.target_web1_name
  port = var.target_group_port
  protocol = var.target_group_protocol
  target_type = var.target_type
  vpc_id = aws_vpc.myvpc.id
}
resource "aws_lb_target_group" "target2" {
  health_check {
    interval = var. health_check_interval
    path = var.health_check_path[1]
    protocol = var.target_group_protocol
    timeout = var.health_check_timeout
    healthy_threshold = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }
  name = var.target_web2_name
  port = var.target_group_port
  protocol = var.target_group_protocol
  target_type = var.target_type
  vpc_id = aws_vpc.myvpc.id
}
resource "aws_lb" "loadbalancer" {
  internal = var.internal
  load_balancer_type = var.load_balancer_type
  subnets = [aws_subnet.public[0].id, aws_subnet.public[1].id]
  security_groups = [aws_security_group.lb_security_groups.id]
  ip_address_type = var.ip_address_type
 tags = {
   Name = var.lb_name
 }
}
resource "aws_lb_target_group_attachment" "ec2-attach1" {
  target_group_arn = aws_lb_target_group.target1.arn
  target_id = aws_instance.web[0].id
  port = var.listerner_port
}
resource "aws_lb_target_group_attachment" "ec2-attach2" {
  target_group_arn = aws_lb_target_group.target2.arn
  target_id = aws_instance.web[1].id
  port = var.listerner_port
}
resource "aws_lb_listener" "mylistener1" {
  load_balancer_arn = aws_lb.loadbalancer.arn
   port = var.listerner_port
   protocol = var.listerner_protocol
   default_action {
    type = var.listiner_type  
    target_group_arn = aws_lb_target_group.target1.arn
   }
}
resource "aws_alb_listener_rule" "listener_path_based" {
  listener_arn = aws_lb_listener.mylistener1.arn
  action {    
  type = var.listiner_type      
  target_group_arn = aws_lb_target_group.target1.arn
    }   
 condition {
    path_pattern {
      values = var.Listener_path_images
    }
  }
}
resource "aws_alb_listener_rule" "listener_path_data" {
  listener_arn = aws_lb_listener.mylistener1.arn
  action {    
  type = var.listiner_type  
  target_group_arn = aws_lb_target_group.target2.arn
    }   
 condition {
    path_pattern {
      values = var.Listener_path_data
    }
  }
}