# MoonBit-FSM Architecture

## Overview

`moon-fsm` is organized as a compact workflow-oriented library:

1. describe transitions with `Builder`
2. validate topology with `validate_report`
3. instantiate an `Engine`
4. execute events through `try_send`, `send`, or `try_send_all`
5. inspect history, audit records, metrics, and snapshots
6. export Mermaid diagrams

The remediation release keeps the runtime small while making acceptance-facing
behavior explicit and testable.

The 0.2.0 expansion also checks the public behavior against a 32-case,
four-domain scenario corpus. The corpus covers approval, order, device, and
support workflows, including success, cancellation, rejection, retry, fault,
and unknown-event paths. It is intentionally deterministic so a reviewer can
reproduce it with `moon run benchmarks` on any supported platform.

## Main Components

### Builder

`Builder[S, E, Ctx]` stores declarative transition data before runtime exists.

Responsibilities:

- collect plain, guarded, and action-bearing transitions
- register `on_enter` and `on_exit` callbacks
- preserve transition definitions for validation and Mermaid export
- materialize runtime maps while flagging duplicate `(state, event)` pairs

### Engine

`Engine[S, E, Ctx]` stores:

- current state
- current context
- transition lookup tables
- optional guard lookup tables
- optional action lookup tables
- lifecycle callback maps
- successful transition history
- audit records for successful and rejected attempts
- execution metrics
- last transition error
- build-time configuration error marker

`try_send(event)` executes transitions in this order:

1. reject invalid build configurations such as duplicate `(state, event)` pairs
2. locate transitions for the current state
3. locate the current event inside that state
4. evaluate any guard for the `(state, event)` pair
5. run the transition action to compute the next context
6. run `on_exit`
7. update `current_state`
8. run `on_enter`
9. append a `TransitionRecord` to history
10. append an `AuditRecord` and update execution metrics

Rejected attempts do not mutate state, context, or successful history. They do
append an audit record and classify the failure in `ExecutionMetrics`. A
`try_send_all(events)` call applies events in order and returns every outcome;
it is deliberately best-effort rather than implicitly transactional.

`checkpoint()` captures state, context, successful history, audit records,
metrics, and the last error. `restore(snapshot)` restores all of those values,
so callers can implement explicit compensation around a batch or a larger
workflow unit.

`send(event)` is intentionally kept as a compatibility wrapper that maps
`TransitionError` to stable strings.

### Validator

`validate_report(builder, initial_state)` produces a `ValidationReport` that is
useful both for developers and for acceptance review:

- `unreachable_states`
- `dead_end_states`
- `duplicate_transitions`
- `states_without_outgoing_edges`

This turns repository self-checking into explicit artifacts instead of ad hoc
inspection notes.

### Mermaid Exporter

`to_mermaid(builder)` keeps the documentation path close to the code path. Guard
and action-bearing transitions are annotated inline so reviewers can see which
edges contain validation or context updates.

## Data Model

The library uses generic parameters:

- `S` for state identifiers
- `E` for events
- `Ctx` for user-defined workflow context

Public structured types introduced in the remediation release include:

- `TransitionError`
- `TransitionRecord[S, E]`
- `DuplicateTransition[S, E]`
- `ValidationReport[S, E]`
- `DispatchOutcome[E]`
- `BatchReport[E]`
- `ExecutionMetrics`
- `AuditRecord[S, E]`
- `EngineSnapshot[S, E, Ctx]`

## Workflow Positioning

This library is intentionally not a full BPM or hierarchical state machine
runtime. Instead, it targets auditable workflow slices where:

- transitions must be easy to inspect
- examples should stay runnable and compact
- validation and CI evidence matter during review
- repository-facing behavior should stay stable across MoonBit upgrades

## Design Constraints

- No external runtime dependencies.
- Generated build output is not part of the reviewed source tree.
- Duplicate transition definitions must be surfaced explicitly.
- The acceptance workflow must be reproducible through docs, scripts, and CI.

## Benchmark Boundary

The checked-in benchmark is a behavioral scenario corpus, not a hardware
throughput claim. Each case specifies an initial state, initial context, event
sequence, expected final state, expected accepted/rejected event counts, and
expected history and audit-entry lengths. The typed runner and CSV data are
kept together so the input is inspectable and the executable assertion catches
accidental behavior drift.
