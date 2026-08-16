# API Reference

## Types

### `Guard[S, E, Ctx]`

Predicate used by guarded transitions. It receives the current state, event,
and context, then returns `Bool`.

### `Callback[S, E, Ctx]`

Lifecycle callback used by `on_enter` and `on_exit`.

### `TransitionAction[S, E, Ctx]`

Action executed during a successful transition. It receives the current state,
event, and context, then returns the next context value.

### `TransitionError`

Structured runtime errors:

- `NoTransitionsForCurrentState`
- `EventNotHandledInCurrentState`
- `GuardRejected`
- `DuplicateTransitionDefinition`
- `InvalidConfiguration`

### `TransitionRecord[S, E]`

Successful transition history entry containing:

- `from`
- `event`
- `to`
- `used_guard`
- `used_action`

### `DuplicateTransition[S, E]`

Structured duplicate-definition marker for a repeated `(state, event)` pair.

### `ValidationReport[S, E]`

Structured validation output containing:

- `unreachable_states`
- `dead_end_states`
- `duplicate_transitions`
- `states_without_outgoing_edges`

### `DispatchOutcome[E]`

One ordered batch result containing the original `event`, a `success` flag,
and an optional structured `TransitionError`.

### `BatchReport[E]`

Batch summary containing all `outcomes`, plus `successful`, `rejected`, and
`complete`. `try_send_all` is best-effort: later events are still attempted after an
earlier rejection.

### `RetryPolicy` and `RetryReport[E]`

`RetryPolicy::new(max_attempts, mode)` provides bounded retries for callers
that can change external context between attempts. `RetryMode` supports
`Never`, `GuardOnly`, `UnknownEventOnly`, and `Recoverable`. Every attempt is
recorded in `RetryReport.attempts`; the API never sleeps or silently discards
an error.

### `BudgetReport[E]`

`try_send_with_budget(events, rejection_budget)` protects an integration from
an error storm. It processes events in order and reports `processed`,
`successful`, `rejected`, and `stopped`. A rejection budget of zero stops at
the first rejected event.

### `GraphSummary[S]`

`graph_summary(builder, initial_state)` reports state and transition counts,
terminal states, branching states, reachable/unreachable states, cycles, and
maximum exploration depth. `workflow_risk_score` provides a deterministic
integer suitable for a review gate, not a production reliability guarantee.

### `WorkflowJournal` and SLA helpers

`WorkflowJournal` stores severity-labelled operational entries and supports
`info`, `warning`, `error`, `critical`, `append_audit`, `acknowledge`,
`acknowledge_ticket`, `for_ticket`, and `unacknowledged_incidents`. The query
layer adds `JournalFilter`, `query_journal`, `summarize_ticket`, and level
counts. `evaluate_sla` and `sla_status` use logical workflow steps rather than
wall-clock time, keeping tests reproducible while allowing an application to
map its own clock or scheduler to steps.

### `ExecutionMetrics`

Counters for attempted, successful, rejected, guard-rejected, unknown-event,
terminal-state, duplicate-configuration, invalid-configuration, and lifecycle
hook executions. `copy()` is used by read APIs to prevent accidental aliasing.

### `AuditRecord[S, E]`

An immutable view of one accepted or rejected attempt, including `from`, `to`,
`event`, `success`, an optional error, and the successful `history_index`.

### `EngineSnapshot[S, E, Ctx]`

A complete checkpoint of state, context, history, audit log, metrics, and last
error. Use `restore` for explicit compensation; snapshots are not persisted
or serialized by the library.

### `Builder[S, E, Ctx]`

Configuration object used to define the state machine before runtime.

### `Engine[S, E, Ctx]`

Runtime object that stores the current state, context, transition tables,
history, and the most recent runtime error.

## Builder API

### `Builder::new()`

Create an empty builder.

### `transition(from, event, to)`

Register a normal transition.

### `transition_if(from, event, to, guard_cond)`

Register a transition guarded by `guard_cond`.

### `transition_do(from, event, to, action)`

Register a transition that updates context during a successful state change.

### `transition_if_do(from, event, to, guard_cond, action)`

Register a guarded transition that also updates context.

### `on_enter(state, callback)`

Register a callback that runs after the engine enters `state`.

### `on_exit(state, callback)`

Register a callback that runs before the engine leaves `state`.

### `build(initial_state, initial_context)`

Create an `Engine` from the configured transitions and hooks. Duplicate
transition definitions are preserved for validation and surfaced as a runtime
configuration error when events are executed.

## Engine API

### `state()`

Return the current state.

### `context()`

Return the current context value.

### `history()`

Return successful `TransitionRecord` entries in execution order.

### `last_error()`

Return the most recent `TransitionError`, if any.

### `metrics()`

Return a copy of current execution counters.

### `audit_log()`

Return a copy of accepted and rejected attempt records in execution order.

### `reset_metrics()`

Reset metrics and clear audit records without changing state, context, or
successful history.

### `checkpoint()`

Capture a complete `EngineSnapshot`.

### `restore(snapshot)`

Restore a previously captured snapshot. This is the recommended primitive for
compensating a best-effort batch when the caller decides the workflow unit
must be rolled back.

### `try_send_all(events)`

Attempt an ordered array of events and return a `BatchReport`. Every event is
represented in `outcomes`; rejected events do not stop later events.

### `try_send(event)`

Attempt to process one event and return `Result[Unit, TransitionError]`.

Recommended when workflow code needs structured handling of guard failures,
missing events, or invalid builder configuration.

### `send(event)`

Compatibility wrapper around `try_send(event)` that returns
`Result[Unit, String]`.

Recommended only when older call sites expect string errors.

## Validation and Helper Functions

### `validate(builder, initial_state)`

Return the list of unreachable states for backwards compatibility.

### `validate_report(builder, initial_state)`

Return a `ValidationReport` for acceptance review and richer diagnostics.

### `duplicate_transition_entries(builder)`

Return duplicate `(state, event)` definitions discovered in a builder.

### `to_mermaid(builder)`

Export builder transitions as Mermaid `stateDiagram-v2` text. Guarded and
action-bearing transitions are annotated inline.

### `format_transition_error(err)`

Convert a structured `TransitionError` into a stable public string.

## Boundary and Scenario Verification

The root package includes regression tests for empty builders, terminal states,
unknown events, guard rejection, duplicate definitions, lifecycle ordering,
history ordering, snapshots, batches, metrics, audit isolation, retries,
budgets, graph analysis, journal queries, SLA boundaries, and empty Mermaid
output. The repository-level scenario runner additionally exercises 44
approval, order, device, and support cases:

```bash
moon test --deny-warn --target all
moon run benchmarks
```

The benchmark cases are documented in
[`benchmarks/data/workflow_cases.csv`](../benchmarks/data/workflow_cases.csv).
