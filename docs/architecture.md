# Architecture

## The problem this repository is shaped around

A disaster recovery plan fails in one of three ways, and almost never in a
fourth:

1. **The copy was never good.** Backups ran, nobody restored one, and the first
   real restore is the first test.
2. **The plan drifted.** The primary changed; the recovery site did not.
3. **Nobody could execute it.** The procedure lived in one person's head, or in
   a wiki page last touched two reorganisations ago.

The layout below exists to attack those three, in that order.

## Layers

```
spec  ──►  terraform  ──►  ansible  ──►  runbook
what          where          how          who
```

Each layer answers exactly one question and hands a defined shape to the next.

### `specs/` — what

Numbered, reviewed decisions. Nothing gets built that is not written here
first. A spec states the RPO and RTO it targets, so every downstream layer has
a number to be measured against instead of an adjective.

Rules: [.github/instructions/specs.instructions.md](../.github/instructions/specs.instructions.md)

### `terraform/` — where

Provisions the recovery site and declares the backup regime. Split in two:

| Path | Responsibility |
|---|---|
| `terraform/*.tf` | Root: naming, tagging, cross-variable invariants, module wiring. Creates nothing itself. |
| `terraform/modules/backup_policy/` | How often data is captured, where copies land, how long they live. |
| `terraform/modules/dr_site/` | The recovery footprint, sized by the chosen strategy. |
| `terraform/environments/<env>/` | Per-environment variable values. No state, no secrets. |

The root module derives the backup interval from the RPO
(`max(5, rpo / 2)` — half the objective leaves room for one retry) and refuses,
via `precondition` blocks, to plan a configuration whose objectives are
arithmetically unreachable. `precondition` rather than `check` because a `check`
block only warns; an impossible DR plan must not be plannable. That is
drift-failure mode #2 caught at `plan` time.

The `dr_summary` output is the contract handed to Ansible.

### `ansible/` — how

Brings hosts on both sides of the pair to the state the plan assumes.

| Role | Responsibility |
|---|---|
| `common` | Baseline every managed host needs: packages, time sync, and a `/etc/dr-brainstorm/site.yml` facts file readable from a console with no network. |
| `backup_agent` | Schedules capture on the primary; verifies restores at the recovery site. |

The same role runs on both sides and branches on `backup_agent_mode`. Restore
verification runs **only** at the recovery site, because restoring a copy where
the source data already sits proves nothing about the copy that crossed the
link. That is failure mode #1.

### `docs/runbooks/` — who

The human procedures. Failover is deliberately manual and deliberately never
triggered from CI: the decision to fail over is a judgement call about blast
radius, and automating the trigger converts a bad five minutes into a bad
afternoon. Automation prepares the failover; a person declares it. That is
failure mode #3.

## Strategy → capacity

`dr_site` owns the single mapping that everything else follows:

| Strategy | Capacity at rest | Hosts warm | Realistic RTO |
|---|---|---|---|
| `backup_restore` | 0% | 0 | hours |
| `pilot_light` | 10% | 1 (control) | ~1 hour |
| `warm_standby` | 50% | 2 | minutes |
| `active_active` | 100% | 2+ | seconds |

Cost rises with every row; RTO falls. Picking a row is the whole design
conversation, which is why it is a spec-level decision and not a variable
someone flips in a tfvars file without review.

## Provider stance

Terraform here uses only built-in constructs (`terraform_data`, locals,
variables) so `init`/`validate`/`plan` all run with **no credentials**. CI
therefore validates every PR from a clean checkout.

Real providers are introduced per-spec, inside the module that needs them,
without changing that module's input/output shape. Rationale and consequences:
[ADR-0001](adr/0001-provider-agnostic-baseline.md).

## Data flow

```
terraform output dr_summary
        │
        ▼
ansible/inventories/<env>/group_vars/all.yml   (dr_* variables)
        │
        ├──► backup_agent config + systemd timer   (interval from RPO)
        └──► /etc/dr-brainstorm/site.yml           (what an operator reads first)
```

Today that hand-off is manual and the two sides are kept in sync by review — a
known gap, called out in
[specs/0001-repository-foundation.md](../specs/0001-repository-foundation.md#follow-up-work).

## Conventions

Naming, linting and review rules live with the code they govern:

- [Terraform](../.github/instructions/terraform.instructions.md)
- [Ansible](../.github/instructions/ansible.instructions.md)
- [Specs](../.github/instructions/specs.instructions.md)
- [Repository-wide](../.github/copilot-instructions.md)
