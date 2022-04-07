variable "cidr_block"{
	description = "CIDR block of the VPC"
}

variable "subnets_cidr" {
	type = list(string)
}

variable "app_subnets_cidr" {
	type = list(string)
}


variable "data_subnets_cidr" {
	type = list(string)
}

