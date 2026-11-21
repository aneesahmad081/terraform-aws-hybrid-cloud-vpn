variable "project_name" {
  type        = string
  description = "Short prefix for created resource names."
  default     = "hybridvpn-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}$", var.project_name))
    error_message = "Use 3-29 lowercase letters, digits and hyphens; start with a letter."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 type in both regions; t3.micro is suitable for a small lab."
  default     = "t3.micro"
}

variable "onprem_vpc_cidr" {
  type        = string
  default     = "10.200.0.0/16"
  description = "Simulated on-premises VPC range (us-east-1)."
}

variable "onprem_subnet_cidr" {
  type        = string
  default     = "10.200.0.0/24"
  description = "Public subnet used by the Libreswan EC2 VPN router."
}

variable "cloud_vpc_cidr" {
  type        = string
  default     = "10.100.0.0/16"
  description = "Private AWS-side VPC range (eu-north-1)."
}

variable "cloud_subnet_cidr" {
  type        = string
  default     = "10.100.0.0/24"
  description = "Private subnet used by the test web server."
}

variable "router_private_ip" {
  type        = string
  default     = "10.200.0.10"
  description = "Router private IPv4 within onprem_subnet_cidr."
}

variable "cloud_server_private_ip" {
  type        = string
  default     = "10.100.0.10"
  description = "Private web server IPv4 within cloud_subnet_cidr."
}
