# Copilot instructions — dr-brainstorm

This repository is managed by GitHub Copilot. Treat everything below as binding
for any change you propose here.

## What this repository is

A spec-driven laboratory for **disaster recovery** patterns, implemented as
Terraform (provisioning) plus Ansible (configuration and runbook automation).
It is provider-agnostic by default. See [../docs/architecture.md](../docs/architecture.md).

## The one rule that outranks the others

**No implementation without an accepted spec.** If a request would add or change
behaviour in `terraform/` or `ansible/` and no spec in [`../specs/`](../specs/)
covers it, write the spec first and say so. Typo fixes, formatting, comments and
CI plumbing are exempt.

## Working agreement

1. **Read the spec before the code.** Every PR body must cite the spec it
   implements, e.g. `Implements specs/0001-repository-foundation.md`.
2. **Small, single-purpose PRs.** One spec, one concern. Never mix a Terraform
   module change and an Ansible role change unless the spec ties them together.
3. **Everything must pass CI locally first** — the exact commands are in
   [../docs/getting-started.md](../docs/getting-started.md). Do not open a PR
   you have not linted.
4. **Never commit real values.** No credentials, no real hostnames, no real
   region names beyond the documented placeholders. Only `*.example` files.
5. **State a decision as an ADR**, in [../docs/adr/](../docs/adr/), whenever you
   pick a provider, a backend, or a tool. Code that embodies an undocumented
   decision will be rejected.

## Conventions you must follow

- Names: `snake_case` for Terraform and Ansible identifiers, `kebab-case` for
  file names, directories and resource name strings.
- Every Terraform variable and output carries a `description`. Every variable
  that has a valid range carries a `validation` block.
- Every Ansible task has a `name`, uses fully-qualified module names
  (`ansible.builtin.template`, not `template`), and is idempotent.
- Role defaults belong in `defaults/main.yml` (overridable). Role internals
  belong in `vars/main.yml` (not overridable). Do not blur the two.
- Comments explain **why**, never **what**. If a line needs a comment to say
  what it does, rewrite the line.

## Things to refuse

- Adding a cloud provider without an accompanying ADR and spec.
- Committing `*.tfvars`, state files, inventories with real hosts, or anything
  matching [`../.gitignore`](../.gitignore).
- A "failover" that runs automatically from CI. Failover is deliberately manual;
  see [../docs/runbooks/failover.md](../docs/runbooks/failover.md).
- Loosening `terraform validate`, `ansible-lint` (profile `production`) or
  `yamllint` to make a change pass.

## Path-specific rules

More detailed instructions apply per directory — they load automatically:

- [instructions/terraform.instructions.md](instructions/terraform.instructions.md)
- [instructions/ansible.instructions.md](instructions/ansible.instructions.md)
- [instructions/specs.instructions.md](instructions/specs.instructions.md)
