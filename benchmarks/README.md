# Workflow Benchmark Corpus

This directory is a deterministic scenario benchmark for `moon-fsm`. It is
designed to make the project scope and behavior reviewable without depending
on wall-clock timing, CPU model, or a network service.

The checked-in CSV contains 44 representative workflow cases across four
common engineering domains:

- approval and review workflows
- order fulfillment and cancellation
- device boot, fault, and recovery flows
- support ticket assignment, escalation, reopening, and closure

The extended support cases also cover customer waiting, cancellation,
terminal-event storms, and long reopen loops. The runnable examples extend
those scenarios with `examples/support_workflow` for customer operations and
`examples/incident_workflow` for incident commander assignment, mitigation,
rollback, journal ingestion, SLA checks, runbook handover, and closure review.

Each case records the initial state, initial context, event sequence, expected
final state, successful transition count, and rejected-event count. The
executable runner in `main.mbt` uses the same cases as typed data and verifies
the expected history length and audit-entry count after every scenario.

Run the benchmark from the module root:

```bash
moon run benchmarks
```

This is a behavioral scenario benchmark, not a claim about throughput across
hardware. It complements the unit tests by exercising longer, realistic paths
and explicit failure/recovery branches.
