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
    Name = var.vpc_name
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
  Name = var.internet_gateway_name
}
}
# create the NAT gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.elasticip.id
  subnet_id = element(aws_subnet.public.*.id, 0)
tags = {
  Name= var.nat_gateway_name
}
}
# create route public table
resource "aws_route_table" "public" {
 vpc_id = aws_vpc.myvpc.id
 route {
  cidr_block = var.cidr_all_traffic
  gateway_id = aws_internet_gateway.myigw.id
 }
 tags = {
   Name = var.public_route_table_name
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
    cidr_block = var.cidr_all_traffic
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = var.private_route_table_name
  }
}
# route table association with Private Subnets
resource "aws_route_table_association" "privatesubnet" {
  count = var.required_number_of_privatesubnets==null ? length(data.aws_availability_zones.available.names) : var.required_number_of_privatesubnets
  subnet_id = element(aws_subnet.private.*.id,count.index)
  route_table_id = aws_route_table.private.id
}
# create  security groups
resource "aws_security_group" "lb_security_groups" {
  vpc_id = aws_vpc.myvpc.id
  tags ={
    Name = var.lb_sg_name
  }
}
resource "aws_security_group_rule" "ingress_rules" {
count = length(var.ingress_rules)
  type              = var.ingress_rules[count.index].type
  from_port         = var.ingress_rules[count.index].from_port
  to_port           = var.ingress_rules[count.index].to_port
  protocol          = var.ingress_rules[count.index].protocol
  cidr_blocks       = [var.ingress_rules[count.index].cidr_block]
  description       = var.ingress_rules[count.index].description
  security_group_id = aws_security_group.lb_security_groups.id
}

resource "aws_security_group_rule" "allow_all" {
  count = length(var.egress_rules)
  type             = var.egress_rules[count.index].type
  to_port           = var.egress_rules[count.index].to_port
  protocol          = var.egress_rules[count.index].protocol
  from_port         = var.egress_rules[count.index].from_port
  security_group_id = aws_security_group.lb_security_groups.id
}

resource "aws_security_group" "bastion_security_groups" {
  vpc_id = aws_vpc.myvpc.id
  tags ={
    Name = var.bastion_sg_name
  }
}
# sg- rules for bastion host
resource "aws_security_group_rule" "ingress_rules_bastion" {
count = length(var.ingress_rules)
  type              = var.ingress_rules_bastion_host[count.index].type
  from_port         = var.ingress_rules_bastion_host[count.index].from_port
  to_port           = var.ingress_rules_bastion_host[count.index].to_port
  protocol          = var.ingress_rules_bastion_host[count.index].protocol
  cidr_blocks       = [var.ingress_rules_bastion_host[count.index].cidr_block]
  description       = var.ingress_rules_bastion_host[count.index].description
  security_group_id = aws_security_group.bastion_security_groups.id
}
resource "aws_security_group_rule" "allow_all_bastion" {
  count = length(var.egress_rules)
  type              = var.egress_rules[count.index].type
  to_port           = var.egress_rules[count.index].to_port
  protocol          = var.egress_rules[count.index].protocol
  from_port         = var.egress_rules[count.index].from_port
  security_group_id = aws_security_group.lb_security_groups.id
}

# Web server security group
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
#  create Database security group
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
# create ec2-instance for Bastion Host
# lookup(map, key, [default]) - Performs a dynamic lookup into a map variable based on the region
resource "aws_instance" "bastion" {
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
  subnet_id = element(aws_subnet.private.*.id, count.index)
  security_groups = [aws_security_group.webtraffic.id]
   key_name = aws_key_pair.keypair.key_name
  tags = {
  Name = "DBserver-${count.index+1}"
  }
 }
# create  Elastic IP
 resource "aws_eip" "elasticip" {
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
   name = var.lb_name
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