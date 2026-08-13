---
applyTo: "ansible/**"
---

# Ansible rules

## Structure

- `playbooks/` holds entry points only. A playbook lists roles and asserts
  preconditions; it contains no configuration logic.
- `roles/<name>/` is the unit of reuse. Layout:
  - `tasks/main.yml` — what to do, split into `tasks/<topic>.yml` when it grows
    past roughly 60 lines.
  - `handlers/main.yml` — restarts and reloads, never configuration.
  - `templates/*.j2` — rendered files, always with `{{ ansible_managed }}` in a
    header comment.
  - `defaults/main.yml` — the role's public API. Overridable from inventory.
  - `vars/main.yml` — the role's internals. **Not** meant to be overridden.
  - `meta/main.yml` — `galaxy_info` plus real `dependencies`.
- `inventories/<env>/` holds `hosts.ini` and `group_vars/`. Committed
  inventories are examples; real ones are generated from Terraform output.

## Style

- `ansible-lint` runs with `profile: production`. It must pass with zero
  findings. Do not add to `skip_list` to silence a real problem.
- Fully-qualified module names always: `ansible.builtin.template`,
  `ansible.builtin.systemd_service`, `community.general.timezone`.
- Every task and every handler has a `name`, written as a sentence in the
  imperative: "Install the backup agent configuration".
- Every role variable is prefixed with the role name (`backup_agent_*`,
  `common_*`). Shared, cross-role facts use the `dr_*` prefix and live in
  `group_vars/`.
- Idempotence is not optional. Prefer modules over `command`/`shell`; when a
  command is genuinely required, guard it with `creates`, `removes` or a
  `changed_when` that tells the truth.
- File modes are quoted strings (`"0644"`), never bare octal.
- Templates that render shell must pass `bash -n`; use `validate:` on the task.

## DR-specific rules

- The `dr_*` variables in `group_vars/all.yml` mirror the Terraform
  `dr_summary` output. When one changes, change the other in the same PR.
- Anything scheduled must derive its interval from `dr_rpo_minutes`. Never
  hardcode a schedule.
- Roles must behave correctly on **both** sides of the pair. Branch on
  `backup_agent_mode` / `dr_site_role`, never assume the primary.
- Never write a task that performs a failover. Failover is manual, by design.

## Forbidden

- Plaintext secrets. Use Ansible Vault, and never commit the vault password.
- Real hostnames or IPs outside the documented example ranges
  (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`).
- `gather_facts: false` on the baseline playbook — the roles depend on facts.
