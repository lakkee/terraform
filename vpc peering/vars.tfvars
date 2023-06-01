variable "vpc1_cidr_block" {
  default     =  "10.0.0.0/16"
}

variable "vpc2_cidr_block" {
  default     = "172.168.0.0/16"
}

variable "frontend_subnet_cidr_block" {
  default     = "10.0.1.0/24"
}

variable "backend_subnet_cidr_block" {
  default     = "10.0.2.0/24"
}

variable "dmz_subnet_cidr_block" {
  default     = "172.168.1.0/24"
}

variable "mgmt_subnet_cidr_block" {
  default     = "172.168.2.0/24"
}


variable "frontend_inbound_ports" {
  type        = list(number)
  default     = [80,443,8080]
}


variable "backend_inbound_ports" {
  type        = list(number)
  default     = [1433]
}

variable "mgmt_inbound_ports" {
  type        = list(number)
  default     = [443, 80, 3389, 22]
}

