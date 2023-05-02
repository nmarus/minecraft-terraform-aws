#--------------------------------------------------------------
# General
#--------------------------------------------------------------

variable "name_prefix" {
  description = "Naming prefix to be used when creating resources."
  type        = string
  default     = "minecraft"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "default_tags" {
  description = "Default tags to be applied to all resources."
  type        = map(string)
  default     = {}
}

#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "port" {
  description = "TCP port for minecraft"
  type        = number
  default     = 25565
}

variable "allowed_cidrs" {
  description = "Allow these CIDR blocks to the server - default is the Universe"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

#--------------------------------------------------------------
# S3 Storage
#--------------------------------------------------------------

variable "bucket_object_versioning" {
  description = "Value of the bucket object versioning"
  type        = bool
  default     = false
}

variable "bucket_force_destroy" {
  description = "Value of the bucket force destroy"
  type        = bool
  default     = true
}

#--------------------------------------------------------------
# Compute
#--------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type/size"
  type        = string
  default     = "t2.medium"
}
