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

