---
applyTo: "specs/**/*.md"
---

# Spec rules

A spec is the contract. Code is one possible implementation of it. If they
disagree, the spec is right and the code is a bug — or the spec needs an
explicit revision, in the same PR.

## Naming and lifecycle

- File name: `NNNN-kebab-case-title.md`, `NNNN` zero-padded, allocated by taking
  the next unused number. CI enforces this.
- `Status` moves in one direction: `Draft` → `Accepted` → `Implemented`, or
  → `Superseded` (which must name the superseding spec).
- Never rewrite an `Implemented` spec in place. Write a new one that supersedes
  it, and update the old one's `Status` and `Superseded by` fields.

## Required sections

CI fails the build if any of these are missing:

- `## Context` — the situation and the forces. What breaks today.
- `## Decision` — what is being done, stated as a decision, not a wish list.
- `## Scope` — with an explicit **Out of scope** subsection. This is the section
  most often skipped and the one that saves the most argument later.
- `## Acceptance criteria` — a checklist a reviewer can mechanically verify.

The `- **Status:** ...` metadata line is also required and must be one of
`Draft`, `Accepted`, `Implemented`, `Superseded`.

## How to write one

- Start from [TEMPLATE.md](../../specs/TEMPLATE.md). Do not invent a new shape.
- Acceptance criteria must be checkable by running a command or reading a file.
  "Backups are reliable" is not a criterion. "`ansible-lint` exits 0" is.
- Quantify DR claims. Every spec that touches recovery states its RPO and RTO in
  minutes, or explicitly says it does not affect them.
- Record what was rejected and why, under `## Alternatives considered`. A spec
  with no rejected option was not a decision.
- Keep specs short. If one runs past roughly two pages, it is two specs.

## Relationship to ADRs

- **Spec** = what we are going to build, and how we will know it works.
- **ADR** ([docs/adr/](../../docs/adr/)) = a durable technical choice and its
  consequences (provider, backend, tooling).

A spec that picks a provider, a state backend, or a core tool must add the
corresponding ADR in the same PR and link to it.
