# Architecture Decision Records

Durable technical choices and their consequences. An ADR records a decision that
is expensive to reverse: a cloud provider, a state backend, a core tool.

| # | Title | Status | Date |
|---|---|---|---|
| [0001](0001-provider-agnostic-baseline.md) | Provider-agnostic Terraform baseline | Accepted | 2026-08-13 |

## When to write one

Whenever a change embodies a decision that a future reader would otherwise have
to reverse-engineer from the code — and especially when the reasoning includes
something that was rejected.

An ADR is not a spec. The [spec](../../specs/) says what gets built and how
we will verify it; the ADR says why this shape and not the other one, and what
that costs us.

## Format

Follow [0001](0001-provider-agnostic-baseline.md): status, date, supersedes
chain, then Context / Decision / Consequences (good, bad, neutral) /
Alternatives considered / Review trigger.

The **Review trigger** matters. It names the event that should make someone
reopen the decision, so an ADR expires on purpose rather than quietly becoming
wrong.

## Lifecycle

ADRs are immutable once `Accepted`. To change a decision, write a new ADR that
supersedes the old one and update both `Supersedes` / `Superseded by` fields.
