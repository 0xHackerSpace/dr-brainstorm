# Runbook — Failover to the recovery site

- **Trigger:** a human decision. Never automated, never run from CI.
- **Expected duration:** within the environment's declared RTO.
- **Reversible:** partially. See [Failback](#failback) before you start.

> **Why this is manual.** Deciding to fail over is a judgement about blast
> radius, not a threshold. An automated trigger turns a bad five minutes into a
> bad afternoon, and a flapping health check into two live sites writing to
> divergent data. Automation prepares the failover; a person declares it.

## Before you start

Read `/etc/dr-brainstorm/site.yml` on any managed host. It states the strategy,
the RPO, the RTO and the backup target for that environment, and it is readable
from a console with no network and no wiki.

## 0. Declare

- [ ] An incident commander is named and has said the words "we are failing
      over". Write down the time.
- [ ] The reason is recorded — primary unreachable, data corrupted, region-wide
      outage, or a planned exercise.
- [ ] Communications channel is open and someone other than the commander is
      handling it.

## 1. Stop the bleeding at the primary

- [ ] Stop the backup timer, so a corrupted primary cannot overwrite good
      copies:

      systemctl stop dr-backup-agent.timer
      systemctl disable dr-backup-agent.timer

- [ ] If the primary is reachable and the data is suspect, fence it. Two sites
      accepting writes is worse than an outage.

## 2. Confirm what you are about to restore

- [ ] Check the age of the latest snapshot against the RPO:

      /usr/local/sbin/dr-backup-verify

- [ ] Record the actual data loss window. If the newest good copy is older than
      the RPO, the incident now includes data loss — say so explicitly, in
      writing, before continuing.

## 3. Bring up the recovery site

- [ ] Converge the recovery hosts to baseline:

      cd ansible
      ansible-playbook playbooks/main.yml --limit recovery

- [ ] For `backup_restore` and `pilot_light`, scale the site up first — capacity
      at rest is 0% and 10% respectively (see
      [architecture.md](../architecture.md#strategy--capacity)).
- [ ] Restore the latest verified snapshot.

## 4. Cut over

- [ ] Repoint DNS / the load balancer to the recovery endpoint
      (`terraform output recovery_site_endpoint`).
- [ ] Confirm from **outside** your own network. A check that runs inside the
      recovery site proves the site is up, not that anyone can reach it.
- [ ] Record the time. RTO is measured from the declaration in step 0 to here.

## 5. Stabilise

- [ ] Enable backups **at the recovery site** — it is now the primary, and it is
      currently running with no copies of its own:

      systemctl enable --now dr-backup-agent.timer

- [ ] Update the inventory so the recovery group is `backup_agent_mode: source`.
- [ ] Confirm the first post-failover backup completes.

## Failback

Failback is a second failover, in the other direction, and it deserves the same
ceremony. Do not treat it as cleanup. Plan it as its own change, at a time you
choose, with the same checklist.

## After the incident

- [ ] Record the actual RTO and the actual data loss window.
- [ ] Compare both against the declared `dr_rto_minutes` and `dr_rpo_minutes`.
- [ ] If reality missed the declaration, that is a spec change, not a note in a
      retrospective. Open one.
