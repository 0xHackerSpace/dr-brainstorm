---
mode: agent
description: Draft the next numbered spec in specs/ from the repository template.
---

Draft a new specification for: **${input:topic:What is being specified?}**

Steps:

1. List `specs/` and take the next unused four-digit number.
2. Copy the structure of [`specs/TEMPLATE.md`](../../specs/TEMPLATE.md) exactly.
   Do not invent sections or drop required ones.
3. Name the file `specs/NNNN-<kebab-case-title>.md` and set
   `- **Status:** Draft`.
4. Fill in every section. Specifically:
   - **Context** — what breaks or is missing today, in concrete terms.
   - **Decision** — one decision, stated plainly.
   - **Scope** — including an explicit **Out of scope** list.
   - **Acceptance criteria** — a checklist where every item is verifiable by
     running a command or reading a named file. No subjective items.
   - **Alternatives considered** — at least two, each with the reason it lost.
5. State the RPO and RTO impact in minutes, or say explicitly that there is none.
6. If the spec picks a cloud provider, a state backend, or a core tool, also
   draft the matching ADR in `docs/adr/` and link the two together.
7. Add the spec to the index table in [`specs/README.md`](../../specs/README.md).

Do not write any Terraform or Ansible in this pass. The spec comes first and is
reviewed on its own.
