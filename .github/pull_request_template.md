# Summary

<!-- What changes, in one or two sentences. -->

## Spec

Implements `specs/NNNN-....md`

<!-- Required for any change to terraform/ or ansible/. Exempt: docs, typos,
     formatting, CI plumbing. If exempt, say which exemption applies. -->

## Checks

- [ ] `terraform fmt -recursive -check` clean
- [ ] `terraform validate` passes
- [ ] `terraform plan -var-file=environments/example/terraform.tfvars.example` succeeds
- [ ] `ansible-lint` passes on profile `production`
- [ ] `yamllint .` clean
- [ ] `ansible-playbook playbooks/main.yml --syntax-check` passes
- [ ] No secrets, real hostnames, `*.tfvars` or state files committed

## DR impact

- RPO: <!-- unchanged, or the new value in minutes -->
- RTO: <!-- unchanged, or the new value in minutes -->
- Failover procedure affected: <!-- no, or which runbook was updated -->

## Notes for the reviewer

<!-- Anything non-obvious: rejected alternatives, follow-ups, known gaps. -->
