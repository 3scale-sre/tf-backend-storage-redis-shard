resource "aws_instance" "this" {
  count                   = var.node_count
  ami                     = var.ami_id
  instance_type           = var.instance_type
  key_name                = var.key_pair
  subnet_id               = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  disable_api_termination = var.disable_api_termination
  vpc_security_group_ids  = [var.security_group]
  iam_instance_profile    = var.iam_role
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
    tomap({ "Name" = format("%s-%s-bck-storage0%s-0%s", var.environment, var.project, var.shard_id, count.index + var.index_offset + 1) }),
  )

  lifecycle {
    ignore_changes = [ami]
  }

}

resource "aws_route53_record" "this_internal_dns" {
  count   = var.node_count
  zone_id = var.dns_zone_id
  name    = format("%s-%s-bck-storage0%s-0%s.%s", var.environment, var.project, var.shard_id, count.index + var.index_offset + 1, var.dns_zone_name)
  type    = "A"
  records = [aws_instance.this[count.index].private_ip]
  ttl     = 60
}
