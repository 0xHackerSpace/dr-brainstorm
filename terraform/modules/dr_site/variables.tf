variable "name_prefix" {
  description = "Prefix for resource names, supplied by the root module."
  type        = string
}

variable "region" {
  description = "Region the recovery site is built in."
  type        = string
}

variable "strategy" {
  description = "DR pattern to implement: backup_restore, pilot_light, warm_standby or active_active."
  type        = string

  validation {
    condition     = contains(["backup_restore", "pilot_light", "warm_standby", "active_active"], var.strategy)
    error_message = "strategy must be one of: backup_restore, pilot_light, warm_standby, active_active."
  }
}

variable "rto_minutes" {
  description = "Target Recovery Time Objective in minutes."
  type        = number
}

variable "backup_policy" {
  description = "Identifier of the backup policy feeding this site. Creates the dependency edge from dr_site to backup_policy."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource created by this module."
  type        = map(string)
  default     = {}
}
