# ADR-0001 — Provider-agnostic Terraform baseline

- **Status:** Accepted
- **Date:** 2026-08-13
- **Supersedes:** —
- **Superseded by:** —

## Context

This repository exists to compare disaster recovery patterns, not to run one
company's production. Committing to AWS, Azure or vSphere on day one would:

- make every subsequent pattern an argument about that provider's primitives
  rather than about the pattern;
- require credentials in CI before there is anything worth deploying;
- lock the module interfaces to one vendor's vocabulary (`availability_zone`
  vs `zone` vs `cluster`), which is the hardest thing to unpick later.

At the same time, a repository of empty directories teaches nothing. The
skeleton has to be real enough to plan, lint and reason about.

## Decision

The Terraform baseline uses **only built-in Terraform constructs** —
`terraform_data`, `locals`, `variables`, `check` blocks. No provider is declared
in `terraform/versions.tf`.

Consequently `terraform init -backend=false`, `terraform validate` and
`terraform plan` all run with **zero credentials**, from a clean checkout, in
CI, on any machine.

Concrete providers are introduced **per-spec**, declared inside the module that
needs them, and always behind the module's existing input/output shape. Each
such introduction requires its own ADR.

## Consequences

**Good**

- CI validates every PR end to end, including `plan`, with no secrets to manage.
- Module interfaces are designed around DR concepts (`strategy`, `rpo_minutes`,
  `retention_days`) rather than around one vendor's resource names.
- A contributor can clone and be productive in under a minute.

**Bad**

- `terraform apply` provisions nothing real. The skeleton is a plannable model,
  not infrastructure, and it must be labelled as such so nobody mistakes a green
  plan for a working recovery site.
- Some provider-specific constraints (quota, zone availability, replication
  topology limits) cannot be expressed until a provider lands, so the first
  provider spec will surface interface changes despite the intent above.
- `terraform_data` produces resources with no meaningful drift detection.

**Neutral**

- The `dr_summary` output shape becomes the stable contract between Terraform
  and Ansible. Changing it is a breaking change for the inventory.

## Alternatives considered

**Pick AWS now, port later.** Fastest to something deployable, and the pattern
library would have been AWS-shaped forever. Porting Terraform between providers
is close to a rewrite; the module boundaries would have encoded AWS assumptions
long before anyone noticed.

**Empty module directories with `.gitkeep`.** Honest about the lack of an
implementation, but unlintable and unreviewable — CI would have nothing to check
and the first real spec would have no shape to conform to.

**Terraform CDK / Pulumi for genuine multi-cloud abstraction.** Real multi-cloud
support, at the cost of a language runtime and a much smaller pool of people who
can read the result. The goal is to compare DR patterns, not to build a cloud
abstraction layer.

## Review trigger

Revisit this ADR when the first spec that requires real infrastructure is
accepted. At that point, decide whether the provider is added behind the current
interfaces or whether the interfaces themselves need to change.
