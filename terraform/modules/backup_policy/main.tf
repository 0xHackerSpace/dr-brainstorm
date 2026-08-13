/**
 * backup_policy
 *
 * Describes *what* the backup regime is: how often data is captured, where the
 * copies land, and how long they live. It deliberately does not describe *how* —
 * a cloud-specific backend (AWS Backup plan, Azure Recovery Services policy,
 * Proxmox Backup Server job) is bolted on per-spec without changing this
 * module's interface.
 *
 * Until a provider is chosen, the policy materialises as a `terraform_data`
 * resource so the shape is real, plannable and diffable in CI.
 */

terraform {
  required_version = ">= 1.6.0"
}

locals {
  policy_name = "${var.name_prefix}-backup"

  # A cron expression is the lowest common denominator every backup backend
  # understands, so the schedule is normalised here rather than at each backend.
  schedule_cron = (
    var.interval_minutes < 60
    ? "*/${var.interval_minutes} * * * *"
    : (
      var.interval_minutes < 1440
      ? "0 */${floor(var.interval_minutes / 60)} * * *"
      : "0 3 */${floor(var.interval_minutes / 1440)} * *"
    )
  )

  # Copies that outlive their retention are cost, not safety.
  max_copies_retained = ceil((var.retention_days * 1440) / var.interval_minutes)

  policy = {
    name           = local.policy_name
    source_region  = var.source_region
    target_region  = var.target_region
    schedule_cron  = local.schedule_cron
    retention_days = var.retention_days
    max_copies     = local.max_copies_retained
    cross_region   = var.source_region != var.target_region
    tags           = var.tags
  }
}

resource "terraform_data" "policy" {
  input = local.policy
}
