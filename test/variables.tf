variable "iam_name" {
  description = "name of the iam name"
  type        = string
  default     = "chaos_user_role_wm"

}
variable "node_count" {
  description = "number of nodes to be create"
  type        = number
  default     = "1"

}
variable "zone" {
  description = "name of the iam name"
  type        = string
  default     = " "

}
variable "iam_policy_name" {
  description = "name of the iam name"
  type        = string
  default     = "chaos_iam_policy"
}
variable "clustername" {
  description = "iam policy name"
  type        = string
  default     = "chaos_cluster"

}

variable "vpc_name" {
  description = "name of the vpc"
  type        = string
  default     = "chaos_vpc"

}

variable "vpc_cidir" {
  description = "cidir block for vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet1_cidir" {
  description = "cidir block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}
variable "subnet1_name" {
  description = "name of the subnet1"
  type        = string
  default     = "chaos_subnet1"
}

# variable "availability_zone1" {
#   description = "availability zone for the subnets"
#   type        = string
#   default     = "eu-west-3a"
# }

variable "subnet_zone" {
  description = "availability zone for the subnets"
  type        = string
  default     = "eu-west-3b"
}
variable "subnet2_cidir" {
  description = "subnet2 cidir block"
  type        = string
  default     = "10.0.2.0/24"
}
variable "subnet2_name" {
  description = "name of the subnet2"
  type        = string
  default     = "chaos-subnet2"
}
# variable "security_cidir" {
#   description = "subnet2 cidir block"
#   type        = string
#   default     = "10.0.0.0"
# }
variable "security_group_name" {
  description = "name of the security group"
  type        = string
  default     = "Chaos_security_group"
}

variable "form_port" {
  description = "Enter the from port"
  type        = number
  default     = 22
}

variable "to_port" {
  description = "Enter the to port"
  type        = number
  default     = 22
}

variable "protocol" {
  description = "Enter the to protocol"
  type        = string
  default     = "tcp"
}

variable "bucket_name" {
  description = "Enter the bucket name"
  type        = string
  default     = ""
}

variable "acl_s3" {
  description = "Enter the bucket acl permission"
  type        = string
  default     = "private"
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t3.nano"

}

variable "volume_size" {
  description = "Whether to create an instance Size of the root volume in gigabytes"
  type        = number
  default     = 8
}

variable "name" {
  description = "Name to be used on EC2 instance created"
  type        = string
  default     = "watermelon"
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance; which can be managed using the aws_key_pair resource"
  type        = string
  default     = "chaos-key"
}

variable "region" {
  description = "AWS Region the instance is launched in"
  type        = string
  default     = "eu-west-3"
}

variable "ec2_algorithm" {
  description = "Algorithm for private key in ec2"
  type        = string
  default     = "RSA"
}

variable "ec2_rsa_bits" {
  description = "no of bits for rsa algorithm"
  type        = number
  default     = 4690
}

variable "cloudwatch_log_name" {
  description = "Enter the cloudwatch log name "
  type        = string
  default     = "chaos_log"
}

