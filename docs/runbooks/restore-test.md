# Runbook — Restore test

- **Trigger:** weekly, automatically, at the recovery site. Also on demand
  before any change to the backup regime.
- **Expected duration:** minutes.
- **Reversible:** yes — it restores into a scratch directory and touches nothing
  live.

> A backup that has never been restored is a hypothesis. This runbook is what
> turns it into a fact, and it is the single highest-value thing in the
> repository.

## Automatic

The `backup_agent` role installs `dr-backup-verify.timer` at the recovery site
only, on the schedule in `backup_agent_verify_schedule` (default: Sundays,
04:00). It runs only at the recovery site by design: restoring a copy where the
source data already sits proves nothing about the copy that crossed the link.

Check it is armed:

```bash
systemctl list-timers 'dr-backup-agent-verify*'
journalctl -u dr-backup-agent-verify.service --since '30 days ago'
```

## On demand

```bash
sudo /usr/local/sbin/dr-backup-verify
```

## What it checks

| Check | Failure means |
|---|---|
| A snapshot exists at all | Backups have never run, or never arrived |
| Snapshot age <= RPO | The RPO is not being met right now |
| Snapshot is readable | The copy is corrupt or the medium is failing |
| Restored tree is non-empty | Backups are running but capturing nothing |

The last row is the one that catches the quiet disaster: a scope
misconfiguration where the agent runs green every night and copies an empty
directory.

## What it does not check

- That the restored data is **correct** — only that it is present and readable.
  Application-level validation is per-service and belongs in its own spec.
- That a full restore fits inside the RTO. Verification restores a sample; a
  timed full restore is a separate exercise, and should be run at least
  quarterly.

## When it fails

1. Do not silence the alarm. A failing verification is the system working.
2. Check `journalctl -u dr-backup-agent-verify.service -n 100`.
3. Identify which check failed, using the table above, and treat it as an
   incident against the RPO — not as a monitoring bug.
4. Do not resume normal operations until a verification passes. Until then the
   environment has no proven recovery capability, whatever the dashboards say.

## Related

- [failover.md](failover.md) — step 2 runs this same verification before
  committing to a restore.
- [../architecture.md](../architecture.md) — why verification lives at the
  recovery site.
