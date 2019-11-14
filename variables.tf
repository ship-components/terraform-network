variable "availability_zone_one" {
  description = "The availability zone to use"
  default = "ap-northeast-1a"
}

variable "availability_zone_two" {
  description = "The availability zone to use"
  default = "ap-northeast-1b"
}

variable "ingress_instance_id" {
  description = "The instance ID to attach the elastic IP to too"
}

variable "consul_instance_id" {
  description = "The instance ID to attach the elastic IP to too"
}

variable "vpc_cidr_block" {
  description = "IP address range for entire network"
}
