# Workflow Runtime Expansion Design

## Status

Approved direction: Scheme A, pending review of this written design before
implementation.

Target release: `0.2.0`.

## Context

The repository already provides a generic FSM builder, guarded transitions,
context actions, lifecycle callbacks, execution history, topology validation,
Mermaid export, examples, CI, and a 15-case workflow benchmark. The current
effective MoonBit source is about 1,413 lines, with about 687 lines in the core
library. The OSC2026 project page presents 4,000-10,000 effective MoonBit
lines as a reference range and emphasizes quality, boundaries, tests, and
maintainability.

The expansion must therefore add reusable runtime capability and evidence,
not duplicate code only to increase line count. Existing callers using
`send`, `try_send`, `transition`, `transition_if`, `transition_do`, and
`transition_if_do` must continue to compile and keep their current behavior.

## Goals

- Add a safe checkpoint and rollback model for workflow compensation paths.
- Add batch event processing with per-event structured outcomes.
- Add execution metrics and an audit log that make runtime behavior inspectable.
- Demonstrate the new capabilities in a realistic order fulfillment workflow.
- Expand deterministic benchmark data and boundary tests.
- Keep the package dependency-free and compatible with the current MoonBit
  toolchain and all CI targets.
- Increase effective MoonBit implementation and verification scope toward the
  competition reference range through meaningful behavior and tests.

## Non-Goals

- No full hierarchical state-machine interpreter in this release.
- No external database, scheduler, network transport, or persistence format.
- No breaking change to the existing transition builder or string error API.
- No hardware-dependent throughput claim from the scenario benchmark.

## Public API Design

### Snapshot and rollback

Add a public `EngineSnapshot[S, E, Ctx]` containing the current state,
context, successful history, audit log, execution metrics, and last error at
the checkpoint. Add:

- `Engine::checkpoint() -> EngineSnapshot[S, E, Ctx]`
- `Engine::restore(snapshot) -> Unit`

`restore` is an explicit local rollback operation. It restores observable
engine state and audit counters to the checkpoint boundary; transition maps and
registered callbacks remain unchanged. A snapshot is only meaningful for the
engine instance and generic types from which it was created.

### Batch dispatch

Add public result types:

- `DispatchOutcome[E]`, recording the event, a success flag, and an optional
  `TransitionError`.
- `BatchReport[E]`, recording all outcomes, successful count, rejected count,
  and whether the batch completed without rejection.

Add:

- `Engine::try_send_all(events) -> BatchReport[E]`

Batch dispatch is best-effort and ordered: each event is attempted in input
order, a rejected event is recorded, and later events are still attempted.
This avoids hidden transactional behavior. Callers that need atomic behavior
use `checkpoint`, call `try_send_all`, and `restore` when the report is not
successful.

### Metrics and audit

Add `ExecutionMetrics` with counters for attempted, successful, rejected,
guard-rejected, unknown-event, no-outgoing-state, duplicate-configuration,
and lifecycle-hook executions. Add `AuditRecord[S, E]` with the event,
before/after state, success flag, optional error, and history index where
applicable.

Add:

- `Engine::metrics() -> ExecutionMetrics`
- `Engine::audit_log() -> Array[AuditRecord[S, E]]`
- `Engine::reset_metrics() -> Unit`

The existing `history()` remains the successful-transition-only view. The new
audit log is the complete attempt view, including rejected events, so existing
callers do not change semantics.

## Runtime Semantics

For one event, the existing order remains authoritative:

1. reject build-time duplicate configuration;
2. locate the current state and event;
3. evaluate the guard;
4. run the transition action;
5. run `on_exit`;
6. update the current state;
7. run `on_enter`;
8. append successful history and audit records;
9. update metrics and clear the last error on success.

Rejected events never update context, state, successful history, or the
successful-transition count, but they do update the rejected metrics and
audit log. Snapshot restore removes post-checkpoint successful history and
audit entries and restores counters consistently.

## Files and Responsibilities

- `types.mbt`: public result, snapshot, metrics, and audit types.
- `engine.mbt`: single-event behavior and compatibility methods.
- `batch.mbt`: ordered batch dispatch and report construction.
- `snapshot.mbt`: checkpoint and restore behavior.
- `audit.mbt`: metrics and audit recording helpers.
- `batch_test.mbt`, `snapshot_test.mbt`, and `audit_test.mbt`: focused tests.
- `examples/order_workflow/`: runnable order lifecycle, compensation, batch,
  rollback, metrics, and Mermaid demonstration.
- `benchmarks/data/workflow_cases.csv`: expanded scenario corpus.
- `benchmarks/main.mbt`: deterministic execution and expected-result checks.
- `docs/api_reference.md`, `docs/architecture.md`, and README: public usage
  and semantics.

## Testing Strategy

Tests will be written before each implementation slice and must first fail for
the intended missing API or behavior. The required cases are:

- checkpoint restores state, context, history, metrics, and audit boundary;
- rollback after a rejected batch returns to the checkpoint;
- batch dispatch preserves input order and records every outcome;
- mixed success and rejection produces correct counts;
- guard rejection never runs the action or lifecycle hooks;
- metrics classify each structured error variant;
- audit records preserve state and event order;
- metrics reset does not change machine state or history;
- existing compatibility tests continue to pass;
- order workflow covers payment, shipment, cancellation, return, retry,
  compensation, and Mermaid export;
- expanded benchmark cases cover normal, blocked, invalid, terminal, and
  recovery paths.

## Acceptance Evidence

The implementation is complete only when all of the following are true:

- `moon fmt --check`, `moon info`, and
  `moon check --deny-warn --target all` pass;
- `moon test --deny-warn --target all` passes in CI;
- the new order workflow and benchmark runner pass;
- acceptance script checks the new files and runner;
- README and API/architecture docs describe the new semantics;
- `CHANGELOG.md` and release alignment describe `0.2.0`;
- Mooncakes, GitHub, and GitLink all expose the same final commit and release
  metadata;
- `_build/` and generated artifacts remain untracked.

## Risks and Mitigations

- Snapshot copying could accidentally share mutable arrays. Tests will mutate
  the engine after checkpoint and verify the snapshot remains independent.
- Batch semantics could be mistaken for transactions. The API and docs will
  explicitly describe ordered best-effort behavior and the checkpoint-based
  atomic pattern.
- Metrics could drift from runtime behavior. Each error variant and lifecycle
  path gets a direct test, and the benchmark checks summary counts.
- Scope could grow into a hierarchy rewrite. The non-goal is explicit; this
  release stays focused on auditable workflow execution.
