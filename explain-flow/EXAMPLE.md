# Worked Example (Generic Domain)

This shows the expected shape and depth of a finished walkthrough, using a fictional
single-file batch job so the pattern is portable to any domain (batch jobs, scripts,
pipelines, request handlers).

---

# OrderExportBatchJob 完整流程 / Complete Flow

> Entry point: `src/jobs/OrderExportBatchJob.java`

## 0. Startup

`JobRunner` invokes `OrderExportBatchJob.init()` (`OrderExportBatchJob.java:40-58`):
- Loads `order-export-{profile}.yml` (output directory, partner SFTP profile name, retry
  settings)
- `initSftpInfo()` (`OrderExportBatchJob.java:60-74`): reads the `PARTNER-SFTP` connection
  profile (host/port/credentials) from the shared connection config

Then `run()` is called — the body of the job.

## 1. Input Acquisition (`OrderExportBatchJob.java:80-95`)

Two sources feed the same "orders to export" list, both filtered by `updatedAt <= now - 30m`:

| Source | Method | Condition |
|---|---|---|
| Standard orders | `orderRepository.findExportable(cutoff)` | `status = 'PAID'` and `exportedAt IS NULL` |
| Subscription renewals | `orderRepository.findRenewalsExportable(cutoff)` | `type = 'RENEWAL'` and `exportedAt IS NULL` |

Both lists are merged into `pendingOrders`. The job also lists the local staging directory
(`local.staging.dir`) so it can detect files left over from a previous failed run.

## 2. Processing (`OrderExportBatchJob.java:100-160`)

For each order in `pendingOrders`:
1. Look up line items via `orderItemRepository.findByOrderId(orderId)`
2. `isEligible()` guard — skips orders missing required tax fields, logging a "缺少必要欄位"
   style reason and adding them to `skippedOrders`
3. Build a partner-format record (`buildExportRecord()`) — one flattened row per order
4. Append the row to an in-memory `exportLines` list

No network I/O happens per-order here; this phase is pure DB read + in-memory transform.

## 3. Output / Side Effects (`OrderExportBatchJob.java:165-190`)

- `exportLines` is written to a single file `ORDERS_{yyyyMMddHHmmss}.csv`
- The file is pushed to the partner over SFTP via `sftpService.put(file)`
- On success, every exported order's `exportedAt` is updated in one batch update
- On failure, nothing is marked exported, so the same orders are picked up next run

## 4. Wrap-up (`OrderExportBatchJob.java:195-210`)

1. If `skippedOrders` is non-empty, an email summary is sent and the job's exit code is set
   to `RETRY`
2. If the SFTP push failed outright, the same `RETRY` code is used and the staged CSV is
   left on disk for manual inspection

## Flow Diagram

```
orders table (PAID)          orders table (RENEWAL)
        │                            │
        └───────────┬────────────────┘
                     ▼
          merge → pendingOrders
                     ▼
        ┌─────────────────────────┐
        │ per order:                │
        │  load items → eligibility │
        │  check → build CSV row    │
        └─────────────┬─────────────┘
                       ▼
            write ORDERS_xxx.csv
                       ▼
              SFTP push to partner
                       ▼
        success → mark exportedAt
        failure → leave file, RETRY
                       ▼
        skipped orders → notify + RETRY
```

This job exists to hand off a daily batch of paid/renewed orders to an external fulfillment
partner in the flat-file format their intake system expects, while making failures visible
and re-runnable rather than silently dropping orders.
