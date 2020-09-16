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

variable "elasticsearch_host" {
  type        = string
  default     = ""
  description = "ElasticSearch Host to send redis slow logs in HTTP"
}

variable "elasticsearch_index" {
  type        = string
  default     = "redis-slowlog"
  description = "ElasticSearch index used to store redis slow logs"
}

variable "s3_backups_bucket_name" {
  type        = string
  default     = ""
  description = "S3 bucket name to upload/download redis backups"
}

variable "s3_backups_bucket_prefix" {
  type        = string
  default     = "redis"
  description = "S3 backups bucket prefix"
}

variable "s3_backups_bucket_min_size_check" {
  type        = string
  default     = "1*1024*1024*1024"
  description = "S3 backups bucket file minimum size to check (default 1GB expressed as 1*1024*1024*1024)"
}

variable "s3_backups_bucket_period_check_hours" {
  type        = number
  default     = 24
  description = "S3 backups bucket period to check (default last 24h)"
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

variable "threescale_quay_docker_auth_token" {
  type        = string
  default     = ""
  description = "Secret threescale_quay_docker_auth_token"
}

variable "threescale_github_ssh_key_token" {
  type        = string
  default     = ""
  description = "Secret threescale_github_ssh_key_token"
}

variable "backups_enabled" {
  type        = string
  default     = "prod"
  description = "Enable redis backups only if variable = prod"
}
