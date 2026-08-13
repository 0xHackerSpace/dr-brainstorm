/**
 * Root configuration for a single environment.
 *
 * This root is deliberately thin: it computes shared naming/tagging, validates
 * the DR intent, and wires the modules together. All resource creation lives in
 * ./modules/*.
 *
 * Usage:
 *   terraform init -backend=false
 *   terraform plan -var-file=environments/example/terraform.tfvars
 */

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "dr-brainstorm"
      DRStrategy  = var.dr_strategy
    },
    var.tags,
  )

  # Backups must run at least as often as the RPO allows. Half the RPO gives one
  # free retry before the objective is breached.
  backup_interval_minutes = max(5, floor(var.rpo_minutes / 2))

  # Only patterns with capacity already running can meet a tight RTO.
  warm_capacity_required = contains(["warm_standby", "active_active"], var.dr_strategy)
}

# Reject combinations that cannot meet their own objectives, instead of
# discovering it during a real failover.
#
# These are `precondition` blocks rather than a `check` block on purpose: a
# `check` block only emits a warning and still lets the plan succeed, and a DR
# plan that is arithmetically impossible must not be plannable.
resource "terraform_data" "objectives_are_achievable" {
  input = local.common_tags

  lifecycle {
    precondition {
      condition     = var.primary_region != var.recovery_region
      error_message = "primary_region and recovery_region must differ; a single-site DR plan is not a DR plan."
    }

    precondition {
      condition     = local.warm_capacity_required || var.rto_minutes >= 60
      error_message = "backup_restore and pilot_light cannot meet an RTO under 60 minutes; use warm_standby or raise rto_minutes."
    }

    precondition {
      condition     = local.backup_interval_minutes <= var.rpo_minutes
      error_message = "Derived backup interval exceeds the RPO; lower rpo_minutes is not achievable with scheduled backups."
    }
  }
}

module "backup_policy" {
  source = "./modules/backup_policy"

  name_prefix      = local.name_prefix
  source_region    = var.primary_region
  target_region    = var.recovery_region
  interval_minutes = local.backup_interval_minutes
  retention_days   = var.backup_retention_days
  tags             = local.common_tags
}

module "dr_site" {
  source = "./modules/dr_site"

  name_prefix   = local.name_prefix
  region        = var.recovery_region
  strategy      = var.dr_strategy
  rto_minutes   = var.rto_minutes
  backup_policy = module.backup_policy.policy_id
  tags          = local.common_tags
}
