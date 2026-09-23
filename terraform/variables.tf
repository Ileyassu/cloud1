variable "instance_name" {
  description = "The name tag applied to the EC2 instance"
  type        = string
  default     = "cloud1"
}

variable "region" {
  default = "eu-west-3"
}

variable "public_key_path" {
  default = "~/.ssh/cloud1.pub"
}

variable "instance_type" {
  description = "The AWS hardware size for the server"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  default = 1
}

variable "admin_cidr" {
  description = "Public IP in CIDR"
}
