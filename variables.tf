variable "shard_id" {
  type        = number
  default     = 1
  description = "Redis Shard ID (1,2,3...)"
}

variable "node_count" {
  type        = number
  default     = 3
  description = "Number of nodes per Redis Shard"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment (dev/stg/pro)"
}

variable "project" {
  type        = string
  default     = "eng"
  description = "Project (eng/saas)"
}

variable "dns_zone_id" {
  type        = string
  default     = ""
  description = "Redis Shard DNS Zone Id"
}

variable "dns_zone_name" {
  type        = string
  default     = ""
  description = "Redis Shard DNS Zone Name"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`"
}

variable "security_group" {
  type        = string
  default     = ""
  description = "EC2 Security Group to attach to each EC2 instance"
}

variable "iam_role" {
  type        = string
  default     = ""
  description = "IAM role to attach to each EC2 instance"
}

variable "private_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Private subnets to be used by each EC2 instance"
}

variable "key_pair" {
  type        = string
  default     = "3scale-2020"
  description = "AWS Key pair"
}

variable "ami_id" {
  type        = string
  default     = "ami-0affd4508a5d2481b"
  description = "AWS Centos 7 AMI ID"
}

variable "instance_type" {
  type        = string
  default     = "r5.2xlarge"
  description = "AWS EC2 instance type"
}

variable "root_volume_size" {
  type        = string
  default     = "50"
  description = "Root volume EBS size (in GB)"
}

variable "redis_data_volume_size" {
  type        = string
  default     = "150"
  description = "Redis Data volume EBS size (in GB)"
}

variable "disable_api_termination" {
  type        = bool
  default     = true
  description = "EC2 instance termination protection (true = enabled)"
}

variable "index_offset" {
  type        = number
  default     = 0
  description = "Offset for the instance numeration"
}
