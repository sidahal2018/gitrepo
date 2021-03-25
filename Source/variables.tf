variable "region" {
  default = "us-east-2"
}
variable "vpc-cidr" {
  default= "10.0.0.0/16" 
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
# variable "health_check_path2" {
#   default = "/data/index.html"

# }

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