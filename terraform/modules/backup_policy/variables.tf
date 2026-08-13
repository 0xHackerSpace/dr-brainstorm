variable "name_prefix" {
  description = "Prefix for resource names, supplied by the root module."
  type        = string
}

variable "source_region" {
  description = "Region the data is backed up from."
  type        = string
}

variable "target_region" {
  description = "Region backup copies are replicated to."
  type        = string
}

variable "interval_minutes" {
  description = "Minutes between backup runs. Derived from the RPO by the root module."
  type        = number

  validation {
    condition     = var.interval_minutes >= 5
    error_message = "interval_minutes must be at least 5; anything tighter needs continuous replication, not scheduled backups."
  }
}

variable "retention_days" {
  description = "How long a backup copy is kept before expiry."
  type        = number

  validation {
    condition     = var.retention_days >= 1
    error_message = "retention_days must be at least 1."
  }
}

variable "tags" {
  description = "Tags applied to every resource created by this module."
  type        = map(string)
  default     = {}
}
