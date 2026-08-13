# 0001 — Repository foundation and DR baseline skeleton

- **Status:** Accepted
- **Date:** 2026-08-13
- **Author:** 0xHackerSpace
- **Supersedes:** —
- **Superseded by:** —
- **RPO impact:** none — establishes how RPO is declared and enforced, sets no target
- **RTO impact:** none — establishes how RTO is declared and enforced, sets no target

> **Bootstrap exception.** Every other spec is written, reviewed and merged
> before its implementation. This one lands together with the scaffolding it
> describes, because the process it defines has to exist before it can be
> followed. Subsequent specs get no such exception.

## Context

`dr-brainstorm` exists to compare disaster recovery patterns. Today it is a
README and nothing else, which means:

- There is nowhere to put a pattern. Any DR idea has to be argued in prose,
  and prose loses to whoever is most confident in the room.
- There is no shared vocabulary. "Warm standby" means four different things to
  four people, and nothing at all to a machine.
- There is nothing to review against. A contributor — human or agent — has no
  way to know whether a change is correct, in scope, or in the house style.

There are also forces pulling against just "picking AWS and starting":

- Committing to a provider on day one turns every future pattern into an
  argument about that provider's primitives.
- Credentials in CI, before there is anything worth deploying, is cost and risk
  with no return.
- The repository is agent-managed. Rules that live in a maintainer's head cannot
  be applied by Copilot; they have to be written down and, where possible,
  enforced by CI rather than by review.

The three ways DR plans actually fail — an unverified copy, silent drift, and a
procedure nobody can execute — are the things this foundation has to be shaped
around from the start, not retrofitted.

## Decision

Establish the repository as a **spec-driven, provider-agnostic, CI-validated**
skeleton: `specs/` states intent, `terraform/` provisions, `ansible/`
configures, `docs/runbooks/` carries the human procedures, and GitHub Actions
proves every layer still holds on each pull request.

The skeleton is real code, not placeholders. It plans, lints and runs — with no
cloud credentials — so that the first pattern spec has a working shape to
conform to rather than empty directories to invent one in.

## Scope

**Layout.** The directory tree described in
[docs/architecture.md](../docs/architecture.md), created and populated.

**Terraform.** A root module that names, tags, validates and wires; two modules
with DR-shaped interfaces:

- `backup_policy` — interval derived from the RPO, retention, cross-region flag,
  normalised cron schedule.
- `dr_site` — the strategy → capacity mapping, host list, endpoint.

Skeleton resources use built-in `terraform_data` only, so `init`, `validate` and
`plan` all run with zero credentials. Recorded as
[ADR-0001](../docs/adr/0001-provider-agnostic-baseline.md).

**Ansible.** `playbooks/main.yml` plus two roles:

- `common` — baseline packages, time sync, and a `/etc/dr-brainstorm/site.yml`
  facts file readable from a console with no network.
- `backup_agent` — systemd timer whose interval derives from `dr_rpo_minutes`,
  a working rsync-based reference agent for `file://` targets, and restore
  verification that runs **only** at the recovery site.

**Governance.** `.github/copilot-instructions.md` plus path-scoped
`.github/instructions/*.instructions.md` for Terraform, Ansible and specs; a
`new-spec` prompt; a PR template that requires a spec citation and a stated
RPO/RTO impact.

**CI.** Three jobs — Terraform (fmt, validate, per-module validate, plan),
Ansible (yamllint, ansible-lint on `production`, syntax check, shellcheck of the
templated agent scripts), and Specs (naming, required sections, `Status` line,
relative-link integrity across all Markdown).

**Docs.** Architecture, getting-started, ADR-0001, and the failover and
restore-test runbooks.

### Out of scope

- **Any real cloud provider.** Deferred to the first pattern spec, which must
  bring its own ADR.
- **A remote state backend.** Local state only; the skeleton provisions nothing
  worth protecting. Picking a backend is its own spec.
- **Secret management.** No secret is handled yet. Ansible Vault is named as the
  intended mechanism and nothing more.
- **Automatic sync between `terraform output dr_summary` and the Ansible
  `group_vars`.** Manual and review-enforced for now; see follow-up.
- **Automated failover.** Deliberately excluded, permanently, not just for now.
  Rationale in [docs/runbooks/failover.md](../docs/runbooks/failover.md).
- **Application-level restore correctness.** Verification proves a copy is
  present and readable, not that the data is semantically valid.
- **Molecule or Terratest.** Warranted once there is provider-specific behaviour
  to test; today CI's static checks cover the whole surface.

## Design

### The contract between layers

```
specs/          RPO, RTO, strategy          (a decision)
   │
terraform/      dr_summary output           (a data shape)
   │
ansible/        dr_* group_vars             (host configuration)
   │
runbooks/       what a person does at 3am   (a procedure)
```

Each arrow is a named, inspectable shape. `dr_summary` is the stable contract;
changing it is a breaking change for the inventory and requires a spec.

### Objectives are arithmetic, not adjectives

The root module derives rather than accepts what it can:

- `backup_interval_minutes = max(5, floor(rpo_minutes / 2))` — half the
  objective leaves room for exactly one failed run before the RPO is breached.
- `lifecycle` `precondition` blocks on `terraform_data.objectives_are_achievable`
  reject `backup_restore` or `pilot_light` paired with an RTO under 60 minutes,
  a single-region pair, and an interval that exceeds its own RPO. A site with no
  capacity at rest cannot come up in 30 minutes, and the configuration should
  say so at `plan` time rather than during an incident.

  `precondition` and not `check`: a `check` block emits a warning and lets the
  plan succeed, which is exactly the failure mode this is meant to prevent.
- `dr_site` owns the strategy → capacity ratio table; nothing else may encode
  it.

The same numbers flow into the systemd `OnCalendar` expression and into the
staleness threshold the verifier alarms on, so a change to the RPO cannot
silently leave the schedule behind.

### Verification runs on the far side

`backup_agent` runs on both sides and branches on `backup_agent_mode`. The
source side schedules capture; the target side keeps the timer deliberately
stopped and instead runs `dr-backup-verify` weekly. Restoring a copy where the
source data already sits proves nothing about the copy that crossed the link —
so verification only counts at the recovery site.

The verifier checks four things, in order: a snapshot exists, its age is within
the RPO, it is readable, and the restored tree is non-empty. The last catches
the quiet disaster — a scope misconfiguration that backs up an empty directory,
green every night.

### A working reference agent, meant to be replaced

`dr-backup-agent` is real rsync with `--link-dest` hardlinking and
retention pruning that only runs after the new snapshot is in place. It works
for `file://` targets and refuses anything else with exit 78. Its purpose is to
exercise the schedule, retention and alarm paths end to end before a backend is
chosen — not to be extended into a product.

### Rules as files, not as folklore

Because the repository is agent-managed, every rule is either a file Copilot
loads automatically (`.github/instructions/*.instructions.md`, scoped by
`applyTo`) or a CI check. The spec job enforces naming, required sections and
the `Status` line mechanically, so spec hygiene never depends on a reviewer
noticing.

## Acceptance criteria

- [ ] `terraform -chdir=terraform fmt -recursive -check` exits 0
- [ ] `terraform -chdir=terraform init -backend=false` succeeds with no
      credentials configured
- [ ] `terraform -chdir=terraform validate` exits 0
- [ ] `terraform -chdir=terraform plan -var-file=environments/example/terraform.tfvars.example`
      exits 0 and outputs a `dr_summary` with `backup_interval_minutes = 30`
- [ ] `terraform -chdir=terraform plan -var-file=environments/example/terraform.tfvars.example -var 'dr_strategy=pilot_light'`
      exits **non-zero** on the `objectives_are_achievable` precondition, and
      the same command with `-var 'rto_minutes=120'` exits 0
- [ ] `yamllint .` exits 0
- [ ] `ansible-lint` exits 0 with `profile: production` and an empty `skip_list`
- [ ] `ansible-playbook -i inventories/example/hosts.ini playbooks/main.yml --syntax-check`
      exits 0
- [ ] Every `ansible/roles/*/templates/*.sh.j2`, with Jinja stripped, passes
      `bash -n` and `shellcheck -S warning`
- [ ] `.github/workflows/main.yml` defines the jobs `terraform`, `ansible` and
      `specs`
- [ ] `.github/copilot-instructions.md` exists, and
      `.github/instructions/` contains `terraform`, `ansible` and `specs`
      instruction files each carrying an `applyTo` front-matter key
- [ ] `specs/TEMPLATE.md` exists and contains `## Context`, `## Decision`,
      `## Scope` and `## Acceptance criteria`
- [ ] `docs/` contains `architecture.md`, `getting-started.md`,
      `adr/0001-provider-agnostic-baseline.md`, `runbooks/failover.md` and
      `runbooks/restore-test.md`
- [ ] No relative Markdown link in the repository points at a missing file
- [ ] `git status` is clean after a full local check run — no state files,
      `.terraform/`, `*.tfvars` or fact caches escape `.gitignore`

## Alternatives considered

**Pick a cloud provider now and build something deployable.** Fastest route to
real infrastructure, and it would have made the module interfaces AWS-shaped (or
Azure-shaped) permanently. Porting Terraform across providers is close to a
rewrite, and the boundaries would have encoded one vendor's assumptions long
before anyone noticed. Rejected; see
[ADR-0001](../docs/adr/0001-provider-agnostic-baseline.md).

**Empty directories with `.gitkeep` and documentation only.** Honest about the
absence of an implementation, and useless: nothing to lint, nothing to review
against, and the first real spec would have had to invent the shape anyway. The
skeleton's value is precisely that it already plans and passes.

**A single `main.tf` and a single playbook, split later.** Less structure to
carry while the repository is small. Rejected because the split *is* the
content — the module and role boundaries are the reusable part, and "split
later" reliably means "never, and now it is load-bearing".

**Rules in `CONTRIBUTING.md` only.** Conventional and human-readable, but
Copilot does not load it automatically and CI cannot enforce prose. Scoped
`applyTo` instruction files plus a spec-linting job put the same rules where
both the agent and the machine will actually apply them.

## Risks

- **The skeleton gets mistaken for infrastructure.** A green `plan` provisions
  nothing. Mitigated by stating it in the README, ADR-0001 and here; the real
  test comes with the first provider spec.
- **`terraform_data` interfaces do not survive contact with a real provider.**
  Likely to some degree. ADR-0001 carries an explicit review trigger for exactly
  this moment.
- **The `dr_*` variables and `dr_summary` drift apart.** Today only review
  prevents it — the highest-probability failure in this design, and the first
  follow-up below.
- **The reference agent gets extended instead of replaced.** It is deliberately
  limited to `file://` and exits 78 on anything else, so extending it is more
  work than replacing it.
- **Process overhead deters contribution.** If the spec requirement slows the
  repository to a halt, loosen the exemption list — not the CI checks.

## Follow-up work

1. Generate `ansible/inventories/<env>/group_vars/all.yml` from
   `terraform output -json dr_summary`, closing the manual sync gap.
2. Dynamic inventory from Terraform output, replacing the committed example
   `hosts.ini`.
3. First pattern spec: pick a provider and implement one strategy end to end,
   with its own ADR.
4. Molecule scenarios for both roles, once there is provider-specific behaviour
   worth testing.
5. A timed full-restore exercise runbook — verification samples a restore; it
   does not prove the RTO is achievable.
