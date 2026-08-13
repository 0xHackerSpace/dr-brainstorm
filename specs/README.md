# Specs

Numbered specifications. This is where a change starts.

Nothing in `terraform/` or `ansible/` gets implemented before an accepted spec
covers it. Exempt: typos, formatting, comments, CI plumbing.

## Index

| # | Title | Status | RPO impact | RTO impact |
|---|---|---|---|---|
| [0001](0001-repository-foundation.md) | Repository foundation and DR baseline skeleton | Accepted | none | none |

## Writing one

Start from [TEMPLATE.md](TEMPLATE.md). Copilot users: the `new-spec` prompt in
[../.github/prompts/new-spec.prompt.md](../.github/prompts/new-spec.prompt.md)
does the scaffolding, including allocating the next number.

The rules are in
[../.github/instructions/specs.instructions.md](../.github/instructions/specs.instructions.md).
CI enforces the mechanical ones: file naming, the four required sections, and a
valid `Status` line.

## Lifecycle

```
Draft ──► Accepted ──► Implemented
              └──────► Superseded
```

An `Implemented` spec is never rewritten in place. Write a new one that
supersedes it and update both files' front matter in the same PR.

## Specs vs ADRs

- **Spec** — what we are going to build, and how we will know it works.
- **ADR** ([../docs/adr/](../docs/adr/)) — a durable technical choice and its
  consequences: a provider, a state backend, a core tool.

A spec that makes such a choice ships its ADR in the same PR.
