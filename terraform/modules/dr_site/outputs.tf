output "site_id" {
  description = "Stable identifier of the recovery site."
  value       = terraform_data.site.id
}

output "endpoint" {
  description = "Entry point of the recovery site. Empty string when the site is cold."
  value       = local.endpoint
}

output "hosts" {
  description = "Hosts running at the recovery site at rest, shaped for the Ansible inventory."
  value       = local.hosts
}

output "capacity_ratio" {
  description = "Fraction of primary capacity kept running at the recovery site."
  value       = local.capacity_ratio
}

output "running_at_rest" {
  description = "Whether the recovery site has capacity running before a failover is declared."
  value       = local.running_at_rest
}
