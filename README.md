# MoonBit-FSM

`moon-fsm` is an auditable finite state machine component for MoonBit projects
that need workflow-style state progression without adopting a full BPM runtime.
The remediation release for OSC2026 focuses on reviewable engineering value:
structured transition errors, context-updating actions, execution history,
validator reports, workflow-oriented examples, and reproducible CI.

## Package Identity

- Module name: `Rz-coder8848/moon-fsm`
- Package version: `0.2.1`
- GitHub: [Rz-coder8848/MoonBit-FSM](https://github.com/Rz-coder8848/MoonBit-FSM)
- GitLink: [Douj/moon-fsm](https://gitlink.org.cn/Douj/moon-fsm)
- License: Apache-2.0
- Published on Mooncakes: [Rz-coder8848/moon-fsm v0.2.1](https://mooncakes.io/api/v0/modules/Rz-coder8848/moon-fsm)

## Why This Library

Typical uses for this package include:

- approval and review workflows
- device and UI state orchestration
- agent or simulation state control
- teaching and documenting transition-heavy business rules

The library keeps the public surface small while making the transition path
auditable in code review and acceptance review.

## Re-Review Capabilities

- Typed builder API with guarded transitions and transition actions.
- Structured runtime errors via `try_send(event) -> Result[Unit, TransitionError]`.
- Compatibility layer via `send(event) -> Result[Unit, String]`.
- Transition history through `history()`.
- Checkpoint and rollback through `checkpoint()` and `restore(snapshot)`.
- Ordered best-effort event batches through `try_send_all(events)`, with
  per-event outcomes and explicit compensation support.
- Execution metrics and an audit log for accepted and rejected attempts.
- Validator reports for unreachable states, dead ends, duplicate transitions,
  and states without outgoing edges.
- Mermaid export with guard and action annotations.
- Lifecycle hook coverage with explicit tests for `on_enter` / `on_exit`.
- Four-domain, 32-case benchmark corpus covering approval, order, device, and
  support workflows with deterministic expected outcomes.
- Boundary regression tests for empty machines, dead ends, blocked guards,
  unknown events, duplicate definitions, history ordering, and empty exports.
- Runnable workflow examples and acceptance-oriented CI.

## Install

```bash
moon add Rz-coder8848/moon-fsm
```

## Minimal Example

```moonbit
let builder : @fsm.Builder[String, String, Int] = @fsm.Builder::new()
  .transition_do("Draft", "Submit", "Review", fn(_s, _e, ctx) { ctx + 1 })
  .transition_if_do(
    "Review",
    "Approve",
    "Approved",
    fn(_s, _e, ctx) { ctx >= 2 },
    fn(_s, _e, ctx) { ctx + 10 },
  )

let engine = builder.build("Draft", 1)
ignore(engine.try_send("Submit"))
```

## Workflow Example

The remediation release adds a composite approval workflow example:

```text
stateDiagram-v2
    Draft --> Review.Pending : Submit [action]
    Review.Pending --> Review.Approved : Approve [guard] [action]
    Review.Pending --> Review.Rework : RequestChanges
    Review.Pending --> Cancelled : Cancel
    Review.Pending --> Review.Rejected : Reject
    Review.Rework --> Review.Pending : Resubmit [action]
    Review.Rework --> Cancelled : Cancel
    Review.Rejected --> Error.Validation : Escalate
    Review.Approved --> Closed : Archive
```

The expanded order workflow demonstrates context actions, a guarded shipment,
terminal error handling, lifecycle hooks, batch outcomes, and compensation:

```text
stateDiagram-v2
    Created --> Paid : Pay [action]
    Paid --> Packed : Pack [action]
    Packed --> Shipped : Ship [guard] [action]
    Shipped --> Delivered : Deliver
    Paid --> Cancelled : Cancel
    Packed --> Cancelled : Cancel
    Shipped --> Returned : Return [action]
```

Run it locally with:

```bash
moon run examples/approval_workflow
moon run examples/order_workflow
```

Run the reproducible workflow benchmark corpus:

```bash
moon run benchmarks
```

The benchmark is a scenario benchmark rather than a hardware-dependent
throughput claim. Its input cases are checked in under
[benchmarks/data/workflow_cases.csv](benchmarks/data/workflow_cases.csv), and
the runner verifies expected final states, successful transitions, rejected
events, successful history lengths, and one audit entry for every event
attempt.

The vending machine example was further revised after the formal acceptance
feedback on July 17, 2026. It no longer relies on duplicate `(state, event)`
definitions, and now demonstrates a blocked purchase attempt followed by a
successful retry after more coins are inserted.

## Core API

- `Builder::new()` creates a workflow definition.
- `transition()` and `transition_if()` add plain and guarded transitions.
- `transition_do()` and `transition_if_do()` attach context-updating actions.
- `build()` materializes an `Engine`.
- `try_send()` returns `TransitionError` values for structured handling.
- `history()` returns successful transition records.
- `checkpoint()` and `restore()` provide explicit state/context/history
  snapshots for compensating workflows.
- `try_send_all()` returns ordered `BatchReport` outcomes without silently
  stopping at the first rejected event.
- `metrics()` and `audit_log()` expose execution evidence; `reset_metrics()`
  clears counters and audit entries while retaining the current workflow state.
- `last_error()` exposes the most recent runtime failure.
- `validate_report()` summarizes reachability and duplicate-definition issues.
- `to_mermaid()` exports reviewer-friendly diagrams.

API details live in [docs/api_reference.md](docs/api_reference.md).

## Examples

- `moon run examples/traffic_light`
- `moon run examples/vending_machine`
- `moon run examples/game_npc`
- `moon run examples/approval_workflow`
- `moon run examples/order_workflow`
- `moon run cmd/fsm-cli`

## Verification

The current MoonBit 0.10.3-compatible verification set is:

```bash
moon version --all
moon fmt --check
moon info
moon check --deny-warn --target all
moon test --deny-warn --target all
powershell -ExecutionPolicy Bypass -File scripts/verify_acceptance.ps1 -SkipMooncakes
moon run benchmarks
moon publish --dry-run
```

`moon fmt --deny-warn` and `moon info --deny-warn` are not used because the
current CLI does not expose those flags; the repository instead runs the
equivalent supported checks above. On Windows machines without a system C
compiler, local `moon test --deny-warn --target all` may stop at the `native`
target; the CI workflow remains the source of truth for full multi-target
coverage.

## Release Alignment

- `0.1.0` was the initial Mooncakes publication.
- `0.1.1` was the first OSC2026 re-review remediation release.
- `0.2.0` is the workflow-runtime expansion release with snapshots, batch
  dispatch, metrics, audit records, a 32-case corpus, and a runnable order
  workflow.
- `0.2.1` is the MoonBit 0.10.3 compatibility patch for executable package
  configuration.
- Release alignment details live in [docs/release-alignment.md](docs/release-alignment.md).

## Documentation

- [Architecture](docs/architecture.md)
- [API reference](docs/api_reference.md)
- [Acceptance checklist](docs/acceptance-checklist.md)
- [Release checklist](docs/release-checklist.md)
- [Release alignment](docs/release-alignment.md)

## Notes For Reviewers

- GitHub and GitLink are both public review surfaces for the same codebase.
- Generated build output is intentionally excluded from version control.
- The checked-in competition material is [申报书.md](申报书.md).

## Contributing

Small, reviewable changes are preferred. Before opening a PR, run the same
verification commands listed above and keep examples executable.
