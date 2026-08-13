---
applyTo: "terraform/**/*.tf"
---

# Terraform rules

## Structure

- The root module (`terraform/*.tf`) **wires and validates**. It computes naming
  and tagging, asserts the DR objectives are achievable, and calls modules. It
  creates no resources of its own.
- Every resource lives in a module under `terraform/modules/<name>/`, which must
  contain exactly `main.tf`, `variables.tf`, `outputs.tf` — add `versions.tf`
  only when the module declares a provider.
- Modules are single-purpose and provider-agnostic in their **interface**. A
  module may gain a cloud-specific implementation; its inputs and outputs must
  not change shape when it does.

## Style

- `terraform fmt -recursive` must be clean. CI checks it with `-check -diff`.
- Variables: `description` always, `type` always, `validation` whenever a range
  or enum exists, `default` only when a safe default genuinely exists. A
  required input with a made-up default is a bug.
- Outputs: `description` always. Output the shapes downstream consumers need
  (the Ansible inventory, the runbooks), not raw resource attributes.
- Locals carry the logic. If a `main.tf` has an expression more than two levels
  deep inline, lift it into a named local.
- Cross-variable invariants that a single `validation` block cannot express —
  e.g. "an RTO under 60 minutes needs warm capacity" — go in `lifecycle`
  `precondition` blocks, **not** in a `check` block. A `check` block only warns
  and lets the plan succeed; an impossible DR plan must not be plannable.

## Provider policy

The repository stays provider-agnostic until a spec says otherwise
(see [ADR-0001](../../docs/adr/0001-provider-agnostic-baseline.md)).

- Skeleton resources use the built-in `terraform_data`. This keeps
  `terraform init -backend=false && terraform validate && terraform plan`
  working with zero credentials, which is what CI runs.
- To introduce a real provider: write the spec, write the ADR, declare the
  provider in `required_providers` inside the module that uses it and mirror it
  in `terraform/versions.tf`.
- Never add a provider block that needs credentials to `plan`. CI has none.

## Forbidden

- Hardcoded region names, account IDs, ARNs, subscription IDs, or hostnames
  outside `environments/*/terraform.tfvars.example`.
- Committing `*.tfvars`, `*.tfstate`, `.terraform/`.
- `local-exec` / `remote-exec` provisioners. Configuration is Ansible's job.
- Reading secrets into state. If a value is secret, it comes from a secret store
  at apply time, and the spec must say which one.
