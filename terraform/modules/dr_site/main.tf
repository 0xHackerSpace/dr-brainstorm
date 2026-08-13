/**
 * dr_site
 *
 * The recovery site footprint. The chosen strategy decides how much of it is
 * running before a disaster: a cold site is a policy and nothing else, an
 * active-active site is a full second copy.
 *
 * This module owns the strategy -> capacity mapping. Cloud-specific compute and
 * networking is added per-spec behind this same interface.
 */

terraform {
  required_version = ">= 1.6.0"
}

locals {
  # How much of the primary footprint runs at the recovery site at rest.
  # Cold sites cost nothing and take hours; active-active costs double and takes
  # seconds. Everything else is a point between.
  capacity_ratio = {
    backup_restore = 0.0
    pilot_light    = 0.1
    warm_standby   = 0.5
    active_active  = 1.0
  }[var.strategy]

  running_at_rest = local.capacity_ratio > 0

  # Two hosts is the smallest set that survives losing one of them; a pilot
  # light keeps only the single control node needed to scale the rest up.
  host_count = (
    local.capacity_ratio == 0 ? 0 :
    local.capacity_ratio <= 0.1 ? 1 : 2
  )

  hosts = [
    for i in range(local.host_count) :
    {
      name   = format("%s-recovery-%02d", var.name_prefix, i + 1)
      role   = i == 0 ? "control" : "workload"
      region = var.region
    }
  ]

  endpoint = local.running_at_rest ? "${var.name_prefix}-recovery.${var.region}.internal" : ""
}

resource "terraform_data" "site" {
  input = {
    name           = "${var.name_prefix}-recovery"
    region         = var.region
    strategy       = var.strategy
    capacity_ratio = local.capacity_ratio
    rto_minutes    = var.rto_minutes
    backup_policy  = var.backup_policy
    tags           = var.tags
  }
}

resource "terraform_data" "host" {
  for_each = { for h in local.hosts : h.name => h }

  input = each.value

  # Hosts are useless without something to restore into them.
  depends_on = [terraform_data.site]
}
