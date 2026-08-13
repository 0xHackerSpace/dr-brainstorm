# dr-brainstorm

A repository for brainstorming, specifying and prototyping **disaster recovery (DR)** strategies
and solutions as code.

The goal is not to run one company's production DR. It is to build a reusable, provider-agnostic
skeleton where a DR pattern can be written down as a spec, implemented as Terraform + Ansible, and
validated in CI — so patterns can be compared instead of argued about.

## Layout

```
terraform/          Infrastructure provisioning (recovery site, backup policy)
  modules/          Reusable, single-purpose modules
  environments/     Per-environment tfvars (no state, no secrets)
ansible/            Configuration management and runbook automation
  playbooks/        Entry points
  roles/            Reusable roles
  inventories/      Static inventories / dynamic inventory config
.github/            CI workflows and GitHub Copilot instructions
docs/               Architecture, conventions, ADRs, runbooks
specs/              Numbered specifications — the source of truth for what gets built
```

Full description of each area: [docs/architecture.md](docs/architecture.md).

## How work happens here

This repository is **spec-driven** and **agent-managed** (GitHub Copilot). Nothing meaningful gets
implemented before it exists as a spec in [specs/](specs/).

1. Write a spec from [specs/TEMPLATE.md](specs/TEMPLATE.md) — `specs/NNNN-short-name.md`.
2. Get it reviewed and merged as `Status: Accepted`.
3. Implement it in `terraform/` and/or `ansible/`, referencing the spec number in the PR.
4. CI validates format, syntax and lint on every PR.

The rules an agent must follow are in [.github/copilot-instructions.md](.github/copilot-instructions.md)
and the path-scoped files in [.github/instructions/](.github/instructions/).

## Provider stance

The Terraform code is **provider-agnostic by default**. Root and module skeletons use only built-in
Terraform constructs (`terraform_data`, locals, variables), so `terraform validate` runs in CI with
no cloud credentials. Concrete providers are introduced per-spec, behind a module boundary, and the
decision is recorded as an ADR in [docs/adr/](docs/adr/).

See [ADR-0001](docs/adr/0001-provider-agnostic-baseline.md).

## Getting started

```bash
# Terraform — validation only, no credentials needed
cd terraform
terraform init -backend=false
terraform fmt -recursive -check
terraform validate

# Ansible — syntax check against the example inventory
cd ansible
ansible-playbook -i inventories/example/hosts.ini playbooks/main.yml --syntax-check
ansible-lint
```

More detail: [docs/getting-started.md](docs/getting-started.md).

## Status

Bootstrapping. The first spec is
[specs/0001-repository-foundation.md](specs/0001-repository-foundation.md).
