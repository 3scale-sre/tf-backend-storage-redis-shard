resource "aws_instance" "this" {
  count                   = var.node_count
  ami                     = var.ami_id
  instance_type           = var.instance_type
  key_name                = var.key_pair
  subnet_id               = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  disable_api_termination = var.disable_api_termination
  vpc_security_group_ids  = [var.security_group]
  iam_instance_profile    = var.iam_role
  user_data = templatefile("${path.module}/storage-userdata.tpl", {
    HOSTNAME                             = format("bck-storage0%s-0%s", var.shard_id, count.index + 1)
    DNS_ZONE                             = var.dns_zone_name
    THREESCALE_QUAY_DOCKER_AUTH_TOKEN    = var.threescale_quay_docker_auth_token
    THREESCALE_GITHUB_SSH_KEY_TOKEN      = var.threescale_github_ssh_key_token
    ELASTICSEARCH_HOST                   = var.elasticsearch_host
    ELASTICSEARCH_INDEX                  = var.elasticsearch_index
    BACKUPS_ENABLED                      = var.backups_enabled
    S3_BACKUPS_BUCKET_NAME               = var.s3_backups_bucket_name
    S3_BACKUPS_BUCKET_PREFIX             = var.s3_backups_bucket_prefix
    S3_BACKUPS_BUCKET_MIN_SIZE_CHECK     = var.s3_backups_bucket_min_size_check
    S3_BACKUPS_BUCKET_PERIOD_CHECK_HOURS = var.s3_backups_bucket_period_check_hours
  })
  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }
  ebs_block_device {
    volume_type           = "gp2"
    volume_size           = var.redis_data_volume_size
    delete_on_termination = true
    device_name           = "/dev/xvdf"
  }
  tags = merge(
    var.tags,
    tomap({"Name" = format("%s-%s-bck-storage0%s-0%s", var.environment, var.project, var.shard_id, count.index + 1)}),
  )
}

resource "aws_route53_record" "this_internal_dns" {
  count   = var.node_count
  zone_id = var.dns_zone_id
  name    = format("bck-storage0%s-0%s.%s", var.shard_id, count.index + 1, var.dns_zone_name)
  type    = "A"
  records = [aws_instance.this[count.index].private_ip]
  ttl     = 60
}
