variable "project" {
  description = "Short project identifier, used as a prefix for every named resource."
  type        = string
  default     = "dr-brainstorm"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.project))
    error_message = "project must be 3-24 chars, lowercase alphanumeric or hyphen, starting with a letter."
  }
}

variable "environment" {
  description = "Deployment environment this configuration targets."
  type        = string

  validation {
    condition     = contains(["example", "dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: example, dev, staging, prod."
  }
}

variable "primary_region" {
  description = "Region identifier of the primary site. Format is provider-specific."
  type        = string
}

variable "recovery_region" {
  description = "Region identifier of the recovery site. Must differ from primary_region."
  type        = string
}

variable "dr_strategy" {
  description = <<-EOT
    DR pattern this environment implements:
      backup_restore - restore from backups into a cold site
      pilot_light    - minimal always-on core, scaled up on failover
      warm_standby   - scaled-down but running replica
      active_active  - both sites serve traffic
  EOT
  type        = string

  validation {
    condition     = contains(["backup_restore", "pilot_light", "warm_standby", "active_active"], var.dr_strategy)
    error_message = "dr_strategy must be one of: backup_restore, pilot_light, warm_standby, active_active."
  }
}

variable "rpo_minutes" {
  description = "Target Recovery Point Objective in minutes. Drives backup/replication frequency."
  type        = number

  validation {
    condition     = var.rpo_minutes > 0 && var.rpo_minutes <= 10080
    error_message = "rpo_minutes must be between 1 and 10080 (7 days)."
  }
}

variable "rto_minutes" {
  description = "Target Recovery Time Objective in minutes. Drives how much capacity stays warm."
  type        = number

  validation {
    condition     = var.rto_minutes > 0 && var.rto_minutes <= 10080
    error_message = "rto_minutes must be between 1 and 10080 (7 days)."
  }
}

variable "backup_retention_days" {
  description = "How long backup copies are kept at the recovery site."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Extra tags/labels merged into the common tag set applied to every resource."
  type        = map(string)
  default     = {}
}
