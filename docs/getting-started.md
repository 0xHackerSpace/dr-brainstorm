# Getting started

Everything here runs on a laptop with no cloud account and no credentials. That
is deliberate: CI runs exactly these commands, so if they pass locally the PR
passes.

## Prerequisites

| Tool | Version | Why |
|---|---|---|
| Terraform | >= 1.6 | `terraform_data`, `check` blocks |
| Python | >= 3.11 | Ansible runtime |
| ansible-core | >= 2.15 | `ansible.builtin.systemd_service` |
| ansible-lint | >= 24 | `production` profile |
| yamllint | any recent | YAML style |
| shellcheck | any recent | templated agent scripts |

```bash
pip install ansible-core ansible-lint yamllint
ansible-galaxy collection install -r ansible/requirements.yml
```

## The full local check

Run this before opening a PR. It mirrors
[.github/workflows/main.yml](../.github/workflows/main.yml).

```bash
# --- Terraform -------------------------------------------------------------
cd terraform
terraform fmt -recursive -check -diff
terraform init -backend=false -input=false
terraform validate
terraform plan -var-file=environments/example/terraform.tfvars.example
cd ..

# --- Ansible ---------------------------------------------------------------
yamllint .
ansible-lint
cd ansible
ansible-playbook -i inventories/example/hosts.ini playbooks/main.yml --syntax-check
cd ..
```

## Working with the Terraform layer

```bash
cd terraform

# See what a different DR posture would produce, without editing any file:
terraform plan \
  -var-file=environments/example/terraform.tfvars.example \
  -var 'dr_strategy=pilot_light' -var 'rto_minutes=120'
```

Try `-var 'dr_strategy=pilot_light'` **without** raising `rto_minutes` and the
plan exits non-zero on the `objectives_are_achievable` preconditions in
[terraform/main.tf](../terraform/main.tf) — a cold-ish site cannot meet a
30 minute RTO, and the configuration says so rather than letting you find out
during an incident.

Adding a new environment:

```bash
mkdir -p terraform/environments/staging
cp terraform/environments/example/terraform.tfvars.example \
   terraform/environments/staging/terraform.tfvars.example
# edit, then plan with -var-file=environments/staging/terraform.tfvars.example
```

Real values go in `terraform.tfvars` (gitignored). Only `*.example` is committed.

## Working with the Ansible layer

Nothing here needs real hosts to lint. To actually converge something, point the
inventory at a throwaway VM or container.

```bash
cd ansible

ansible-playbook playbooks/main.yml --syntax-check
ansible-playbook playbooks/main.yml --check --diff          # dry run
ansible-playbook playbooks/main.yml --limit recovery        # one side only
ansible-playbook playbooks/main.yml --tags backup           # one concern only
```

The reference backup agent in
[ansible/roles/backup_agent/templates/dr-backup-agent.sh.j2](../ansible/roles/backup_agent/templates/dr-backup-agent.sh.j2)
is a real, working rsync-based implementation for `file://` targets. It exists
so the schedule, retention and staleness alarms are exercised end to end before
any cloud backend is chosen. It is meant to be replaced, not extended.

## Adding something new

1. `specs/NNNN-your-thing.md`, from [../specs/TEMPLATE.md](../specs/TEMPLATE.md).
   Copilot users: the `new-spec` prompt in
   [.github/prompts/](../.github/prompts/new-spec.prompt.md) does the scaffolding.
2. Get it reviewed and merged with `Status: Accepted`.
3. Implement it. Cite the spec in the PR body.
4. Update the spec to `Status: Implemented` once merged.

The rules a change is reviewed against are in
[.github/copilot-instructions.md](../.github/copilot-instructions.md).

## Troubleshooting

**`terraform validate` complains about a missing provider** — you added a
provider block. Run `terraform init` again, and check you actually meant to; see
[ADR-0001](adr/0001-provider-agnostic-baseline.md).

**`ansible-lint` cannot find role `common`** — you are running it from the wrong
directory, or the `ansible/playbooks/roles` symlink is missing. Run it from the
repository root.

**yamllint disagrees with ansible-lint** — ansible-lint embeds its own yamllint
contract. [.yamllint](../.yamllint) is already reconciled with it; do not
"simplify" `comments-indentation: false` away.
