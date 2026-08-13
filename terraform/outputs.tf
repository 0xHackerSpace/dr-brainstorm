output "name_prefix" {
  description = "Common prefix applied to every resource name in this environment."
  value       = local.name_prefix
}

output "dr_summary" {
  description = "Flattened view of the DR posture this environment implements. Consumed by docs and by the Ansible inventory generator."
  value = {
    strategy                = var.dr_strategy
    primary_region          = var.primary_region
    recovery_region         = var.recovery_region
    rpo_minutes             = var.rpo_minutes
    rto_minutes             = var.rto_minutes
    backup_interval_minutes = local.backup_interval_minutes
    backup_retention_days   = var.backup_retention_days
    warm_capacity           = local.warm_capacity_required
  }
}

output "backup_policy_id" {
  description = "Identifier of the backup policy governing replication to the recovery site."
  value       = module.backup_policy.policy_id
}

output "recovery_site_endpoint" {
  description = "Entry point of the recovery site. Empty for cold (backup_restore) strategies."
  value       = module.dr_site.endpoint
}

output "recovery_site_hosts" {
  description = "Hosts provisioned at the recovery site, for the Ansible inventory."
  value       = module.dr_site.hosts
}

output "common_tags" {
  description = "Tag set applied to every managed resource."
  value       = local.common_tags
}
