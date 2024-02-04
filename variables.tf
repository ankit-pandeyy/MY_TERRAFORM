 variable "public_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["192.169.0.0/24", "192.169.2.0/24", "192.169.3.0/24"]
}
 
variable "private_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 default     = ["192.169.4.0/24", "192.169.5.0/24", "192.169.6.0/24"]
}
variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}
#security_groups_variable
variable "ingressCIDRblock" {
    type = list
    default = [ "0.0.0.0/0" ]
}
variable "egressCIDRblock" {
    type = list
    default = [ "0.0.0.0/0" ]
}
#####EC2 variable

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance; which can be managed using the `aws_key_pair` resource"
  type        = string
  default     = "Himanshu_Key"
}
variable "ami" {
    type = string
    default = "***"
}
variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
  default     = "public_subnets.id"
}
variable "instancetype" {
    description = "The VPC ID to launch in"
    type        = string
    default     = "t2.micro"
}
variable "numberofserver" {
    description = "how many do you want to launch"
    type        = number
    default     = 2
}
