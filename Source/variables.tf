variable "region" {
  default = "us-east-2"
}
variable "vpc-cidr" {
  default= "10.0.0.0/16" 
}
variable "vpc_name" {
  default = "vpc_prod"
}

variable "internet_gateway_name" {
  default = "my-internet-get-way"
}

variable "nat_gateway_name" {
  default = "my-nat-get-way"
}
variable "cidr_all_traffic" {
  default= "0.0.0.0/0"
}

variable "public_route_table_name" {
  default = "Public-RouteTable"
  
}

variable "private_route_table_name" {
  default = "Private-RouteTable"
  
}

variable "required_number_of_publicsubnets" {
  default = 2
  
}
variable "required_number_of_privatesubnets"{
  default = 2
}
variable "ingressrules" {
  type = list(number)
  default = [22,80]
}

variable "egressrules" {
  type = list(number)
  default = [0]
}

variable "egress_cidr_blocks" {
  default     = ["0.0.0.0/0"]

}

variable "ingress_rules" {
    type = list(object({
     type         = string 
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default = [
        {
          type       = "ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "Load Balancer Security Group"
        }
    ]
}


variable "egress_rules" {
    type = list(object({
      type        = string 
      from_port   = number
      to_port     = number
      protocol    = string
    }))
    default = [
        {
          type       = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
         
        }
    ]
}

variable "ingress_rules_bastion_host" {
    type = list(object({
      type        = string 
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default = [
        {
          type       = "ingress"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_block  = "71.173.193.5/32"
          description = "Bastion-SG"
        }
    ]
}



variable "instance_type" {
  default = "t2.micro"
  
}
# define variable of  type map

variable "ec2_ami" {
  type = map
  default = {
      us-east-1 = "ami-042e8287309f5df03"
      us-east-2 = "ami-08962a4068733a2b6"
  }
}

variable "required_number_of_target_group"{
  default = 2
}
variable "health_check_interval" {
  default = "10"

}
variable "health_check_path" {
  type = list(string)
  default = ["/images/index.html", "/data/index.html"]

}


variable "target_group_protocol" {
  default     = "HTTP"
}
variable "health_check_timeout" {
  default = "5"
  
}
variable "health_check_healthy_threshold" {
  default     = "5"
}
variable "health_check_unhealthy_threshold" {
  default     = "2"
  }

variable "target_group_port" {
  default = "80"
}

variable "target_type" {
  default = "instance"
}

variable "ip_address_type" {
  default  = "ipv4"
}
variable "load_balancer_type" {
  default  = "application"
}

variable "sg-protocol" {
  default = "tcp"
}


variable "egress-rule-protocol" {
  default = "-1"
}
variable "my_key_pair_name" {
 default =  "siki"
}
#####
variable "bastion_sg_name" {
  default = "Bastion-SG"
}
variable "lb_sg_name" {
  default = "LB-SG"
}
variable "webserver_sg_name" {
  default = "Webserver-SG"
}
variable "DB_sg_name" {
  default = "DB-SG"
}
variable "Bastion_name" {
  default = "Bastion-Host"
}
variable "Elastic_name" {
  default = "EIP"
}
variable "target_web1_name" {
  default = "Target-Grp-1"
}
variable "target_web2_name" {
  default = "Target-Grp-2"
}
######
variable "lb_name" {
  default = "ALB"
}
variable "internal" {
  default = false
}

variable "listerner_port" {
  default = 80
}

variable "listerner_protocol" {
  default = "HTTP"
}
variable "listiner_type" {
  default = "forward"
}

variable "Listener_path_data" {
  default = ["/data/*"]
}

variable "Listener_path_images" {
  default = ["/images/*"]
}