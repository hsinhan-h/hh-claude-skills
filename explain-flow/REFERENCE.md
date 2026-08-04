# Tracing Multi-File / Cross-Service Flows

Use this when the entry point delegates real work to other files, classes, or services —
the single-file walkthrough in SKILL.md isn't enough on its own.

## Finding the next hop

From the entry point, follow control flow outward one layer at a time:

- **In-process calls**: grep for where a method/class is invoked; open the callee fully
  before describing it (same "read before writing" rule as the entry point).
- **HTTP/RPC calls**: find the client instantiation and the endpoint it targets. If the
  target is in a different repo/service you don't have access to, say so explicitly —
  treat it as a named boundary, not a guess ("calls the Payment Service's `/charge`
  endpoint — implementation out of scope").
- **Message queues**: find the producer (what topic/queue, what payload shape) and, if
  available, the consumer. If the consumer lives in another service, name the queue/topic
  as the handoff point rather than fabricating what the consumer does.
- **Scheduled/triggered jobs downstream**: if the flow ends by enqueuing or writing a file
  that another job picks up (as in a batch pipeline), name that as part of phase 4
  (Wrap-up) and stop — don't chase it into a second full flow unless asked.

## Bounding the trace

Depth control matters more than completeness. Default to tracing 1–2 hops beyond the entry
point, stopping at whichever comes first:

- a well-known external system boundary (third-party API, message broker, another team's
  service you can't inspect)
- a hop that would require access you don't have (different repo, different codebase root)
- diminishing relevance to what the user actually asked about

If the user wants deeper tracing, they'll ask — don't default to boiling the ocean.

## Representing it in the doc

- Add a "Components Involved" table right after the title, before phase 0:

  | Component | Role | Location |
  |---|---|---|
  | OrderBatchJob | Entry point, orchestrates the run | `path/to/OrderBatchJob` |
  | PaymentClient | Calls external Payment Service | `path/to/PaymentClient` |
  | Payment Service | External system (out of scope) | n/a |

- Prefix sub-steps with the component name when a phase spans components, e.g.
  "2a. `OrderBatchJob` builds the charge request" / "2b. `PaymentClient` sends it".
- In the ASCII diagram, group boxes by component (a light box-per-component layout is
  enough — no swimlane tooling needed):

```
┌─────────────────┐        ┌──────────────────┐
│ OrderBatchJob    │──────▶│ PaymentClient      │──────▶ Payment Service (external)
│ (entry point)    │       │ (HTTP call)        │
└─────────────────┘        └──────────────────┘
```

Everything else (rules, template, language, no-bug-commentary) follows SKILL.md as normal —
this file only changes how you *find* and *bound* the material, not how you write it up.
