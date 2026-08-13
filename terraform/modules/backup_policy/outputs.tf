output "policy_id" {
  description = "Stable identifier of the backup policy, consumed by dr_site."
  value       = terraform_data.policy.id
}

output "policy_name" {
  description = "Human-readable policy name."
  value       = local.policy_name
}

output "schedule_cron" {
  description = "Normalised cron expression the backup backend should run on."
  value       = local.schedule_cron
}

output "max_copies" {
  description = "Number of copies retained at steady state, given the interval and retention."
  value       = local.max_copies_retained
}

output "policy" {
  description = "Full policy document, for rendering into runbooks and Ansible vars."
  value       = local.policy
}
