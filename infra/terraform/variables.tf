variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your public IP in CIDR form, for example 203.0.113.10/32"
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/devsecops-key.pub"
}

variable "ci_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "k8s_instance_type" {
  type    = string
  default = "t3.small"
}
