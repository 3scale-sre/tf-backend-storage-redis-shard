output "this_internal_dns" {
  description = "List of private DNS names assigned to the storage instances"
  value       = aws_route53_record.this_internal_dns[*].fqdn
}
