# Workflow Runtime Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand `moon-fsm` into a replayable, auditable workflow runtime with checkpoints, ordered batch dispatch, metrics, audit records, a realistic order example, and enough tested MoonBit scope to answer the OSC2026 engineering-volume feedback.

**Architecture:** Keep the existing transition maps and `send`/`try_send` semantics as the compatibility core. Add immutable public snapshot/report records and mutable engine-owned metrics/audit state. Implement single-event recording in one engine path, build batch dispatch on top of `try_send`, and use checkpoint/restore for explicit caller-controlled compensation rather than hidden transactions.

**Tech Stack:** MoonBit `0.10.x` toolchain, `moon.mod`/`moon.pkg`, built-in `Array`/`Map`/`Option`/`Result`, Markdown documentation, PowerShell acceptance scripts, and GitHub Actions.

---

## File Map

- Modify `types.mbt`: public snapshot, dispatch, metrics, and audit records; extend `Engine` with runtime state.
- Modify `engine.mbt`: preserve current transition order while recording metrics and audit outcomes.
- Create `audit.mbt`: typed metric increment and audit-record helpers.
- Create `snapshot.mbt`: checkpoint and restore methods.
- Create `batch.mbt`: ordered best-effort batch dispatch and report methods.
- Create `audit_test.mbt`: error classification, audit ordering, reset behavior, and hook counts.
- Create `snapshot_test.mbt`: independent snapshot state and rollback boundaries.
- Create `batch_test.mbt`: ordered mixed outcomes and explicit rollback pattern.
- Create `examples/order_workflow/main.mbt`: runnable payment, shipment, return, cancellation, compensation, batch, metrics, and Mermaid flow.
- Create `examples/order_workflow/moon.pkg`: executable package import declaration.
- Modify `benchmarks/main.mbt`: add order and compensation scenarios that exercise the new APIs.
- Modify `benchmarks/data/workflow_cases.csv`: expand the checked-in scenario corpus with batch/rollback expectations.
- Modify `.github/workflows/ci.yml`: run the order example and benchmark command in CI.
- Modify `scripts/verify_acceptance.ps1`: require new files and check new CI/example markers.
- Modify `scripts/test_verify_acceptance_output.ps1`: cover missing new acceptance markers.
- Modify `README.md`: document `0.2.0`, new APIs, compensation pattern, and runnable order example.
- Modify `docs/api_reference.md`: document all new public types and methods.
- Modify `docs/architecture.md`: document engine state, audit semantics, snapshot boundaries, and batch behavior.
- Modify `docs/acceptance-checklist.md`: add runtime expansion and order example evidence.
- Modify `docs/release-alignment.md` and `docs/release-checklist.md`: align the new release metadata.
- Modify `CHANGELOG.md`: add the `0.2.0` implementation release.
- Modify `moon.mod`: change version from `0.1.2` to `0.2.0` after implementation is verified.

### Task 1: Add failing tests for the public records

**Files:**
- Create: `audit_test.mbt`
- Create: `snapshot_test.mbt`
- Create: `batch_test.mbt`

- [ ] **Step 1: Write the missing-API tests first**

Add tests that construct a two-state integer-context engine and assert the
following desired public shapes:

```moonbit
///|
test "audit records successful and rejected attempts" {
  let builder : Builder[String, String, Int] = Builder::new()
    .transition_do("Idle", "Start", "Running", fn(_s, _e, ctx) { ctx + 1 })
  let engine = builder.build("Idle", 0)

  ignore(engine.try_send("Start"))
  ignore(engine.try_send("Missing"))
  inspect(engine.metrics().attempted, content="2")
  inspect(engine.metrics().successful, content="1")
  inspect(engine.metrics().rejected, content="1")
  inspect(engine.audit_log().length(), content="2")
  inspect(engine.audit_log()[0].success, content="true")
  inspect(engine.audit_log()[1].error, content="Some(EventNotHandledInCurrentState)")
}

///|
test "checkpoint restores observable runtime state" {
  let builder : Builder[String, String, Int] = Builder::new().transition_do(
    "Idle", "Start", "Running", fn(_s, _e, ctx) { ctx + 1 },
  )
  let engine = builder.build("Idle", 0)
  let checkpoint = engine.checkpoint()

  ignore(engine.try_send("Start"))
  engine.restore(checkpoint)

  inspect(engine.state(), content="Idle")
  inspect(engine.context(), content="0")
  inspect(engine.history().length(), content="0")
  inspect(engine.audit_log().length(), content="0")
  inspect(engine.metrics().attempted, content="0")
}

///|
test "batch dispatch preserves order and reports mixed outcomes" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition("A", "go", "B")
    .transition("B", "finish", "C")
  let engine = builder.build("A", ())

  let report = engine.try_send_all(["go", "missing", "finish"])

  inspect(report.successful, content="2")
  inspect(report.rejected, content="1")
  inspect(report.complete, content="false")
  inspect(report.outcomes.length(), content="3")
  inspect(report.outcomes[0].event, content="go")
  inspect(report.outcomes[1].error, content="Some(EventNotHandledInCurrentState)")
  inspect(engine.state(), content="C")
}
```

- [ ] **Step 2: Run the focused tests and verify the failure is the missing API**

Run:

```powershell
moon test audit_test.mbt snapshot_test.mbt batch_test.mbt --target wasm-gc
```

Expected: compilation fails because `ExecutionMetrics`, `Engine::checkpoint`,
`Engine::try_send_all`, and the related records do not exist yet. Do not add
implementation before seeing this failure.

### Task 2: Implement public records and engine-owned runtime state

**Files:**
- Modify: `types.mbt`

- [ ] **Step 1: Add the records with stable fields**

Add `DispatchOutcome[E]`, `BatchReport[E]`, `ExecutionMetrics`,
`AuditRecord[S, E]`, and `EngineSnapshot[S, E, Ctx]`. Use `TransitionError?`
for optional errors and `Array` fields for ordered data. Extend `Engine` with
mutable `metrics_value` and `audit_entries` fields while leaving existing
transition maps and compatibility fields unchanged.

- [ ] **Step 2: Initialize the new engine fields**

Update `Builder::build` in `builder.mbt` to initialize zeroed metrics and an
empty audit array. Do not change duplicate-transition detection or the
existing `build_error` behavior.

- [ ] **Step 3: Run the focused tests**

Run:

```powershell
moon test audit_test.mbt snapshot_test.mbt batch_test.mbt --target wasm-gc
```

Expected: the tests compile far enough to fail only on methods and behavior,
not on unknown record names or malformed fields.

### Task 3: Implement audit and metrics recording

**Files:**
- Create: `audit.mbt`
- Modify: `engine.mbt`
- Test: `audit_test.mbt`

- [ ] **Step 1: Implement metric constructors and error classification**

Add private helpers that create zeroed metrics, increment the attempted and
successful/rejected counters, and increment exactly one structured error
counter for each `TransitionError` variant. Add `Engine::metrics`,
`Engine::audit_log`, and `Engine::reset_metrics`; reset only metrics and audit
entries, never state, context, or successful history.

- [ ] **Step 2: Refactor `try_send` through one recording path**

Keep the existing guard/action/hook/state/history order. On each failure,
record an `AuditRecord` with the current state as `from` and `to`, `success`
false, the error, and no history index. On success, record `from`, `to`,
success true, no error, and the index of the newly appended history entry.
Update counters exactly once per attempt. Preserve `last_error` and the
existing `send` string conversion.

- [ ] **Step 3: Run focused tests and the existing suite**

Run:

```powershell
moon fmt --check
moon test audit_test.mbt --target wasm-gc
moon test --deny-warn
```

Expected: audit tests and all pre-existing tests pass with no warnings.

### Task 4: Implement checkpoint and restore

**Files:**
- Create: `snapshot.mbt`
- Modify: `types.mbt`
- Test: `snapshot_test.mbt`

- [ ] **Step 1: Implement independent snapshot capture**

Add `Engine::checkpoint` that stores current state, context, cloned history,
cloned audit entries, cloned metrics, and last error. Use new arrays rather
than aliases so later engine pushes cannot mutate the snapshot.

- [ ] **Step 2: Implement restore**

Add `Engine::restore` that replaces current state, context, history, audit,
metrics, and last error from the snapshot. Leave transition maps, guards,
actions, and callbacks untouched.

- [ ] **Step 3: Add rollback and mutation-isolation tests**

Cover a successful transition followed by restore, rejected events after a
checkpoint, and a snapshot taken before later audit/history pushes. Assert
that state, context, history length, audit length, metrics, and `last_error`
all return to the checkpoint values.

- [ ] **Step 4: Run tests**

Run `moon test snapshot_test.mbt --target wasm-gc` and expect all snapshot
tests to pass.

### Task 5: Implement ordered batch dispatch

**Files:**
- Create: `batch.mbt`
- Test: `batch_test.mbt`

- [ ] **Step 1: Implement `Engine::try_send_all`**

Iterate the input array in order, call `try_send` for every event, append a
`DispatchOutcome` for every result, and compute `successful`, `rejected`, and
`complete` from those outcomes. Do not stop after an error and do not create a
second metrics path.

- [ ] **Step 2: Add explicit compensation test**

Take a checkpoint, dispatch a batch containing a rejected event, assert later
events still ran, then restore when `complete` is false and assert the engine
returns to the checkpoint.

- [ ] **Step 3: Run tests and benchmark command**

Run:

```powershell
moon fmt --check
moon test batch_test.mbt --target wasm-gc
moon test --deny-warn
```

Expected: ordered mixed outcomes and explicit rollback pass.

### Task 6: Add a realistic order workflow example

**Files:**
- Create: `examples/order_workflow/moon.pkg`
- Create: `examples/order_workflow/main.mbt`

- [ ] **Step 1: Define the workflow and context**

Use states `Created`, `Paid`, `Packed`, `Shipped`, `Delivered`, `Cancelled`,
and `Returned`. Use events `Pay`, `Pack`, `Ship`, `Deliver`, `Cancel`, and
`Return`; guard `Ship` on a positive package count; attach actions to payment
and packing; register enter/exit hooks that print audit-friendly messages.

- [ ] **Step 2: Demonstrate best-effort batch and checkpoint compensation**

Run a normal batch, print `BatchReport`, metrics, audit count, and Mermaid
diagram. Run a second batch with an invalid event, show the rejection, restore
the checkpoint, and print the compensated state.

- [ ] **Step 3: Run the example**

Run `moon run examples/order_workflow` and expect deterministic final-state,
batch-count, audit-count, metrics-count, and Mermaid output lines.

### Task 7: Expand benchmarks and acceptance checks

**Files:**
- Modify: `benchmarks/main.mbt`
- Modify: `benchmarks/data/workflow_cases.csv`
- Modify: `.github/workflows/ci.yml`
- Modify: `scripts/verify_acceptance.ps1`
- Modify: `scripts/test_verify_acceptance_output.ps1`

- [ ] **Step 1: Add order, rollback, terminal, and audit scenarios**

Expand the CSV from 15 to at least 30 cases, including normal paths, guard
blocks, unknown events, cancellation, returns, terminal-state rejection,
recovery, and batch compensation. Make the typed benchmark runner assert final
state, success count, rejection count, history count, and audit count.

- [ ] **Step 2: Run the benchmark**

Run `moon run benchmarks`; expected output must report every scenario passed.

- [ ] **Step 3: Extend CI and acceptance gate**

Add `moon run examples/order_workflow` and the existing benchmark command to
CI. Require the order example files and the new runtime test files in
`verify_acceptance.ps1`; add failure-injection coverage for a missing marker in
`test_verify_acceptance_output.ps1`.

### Task 8: Update documentation and release metadata

**Files:**
- Modify: `README.md`
- Modify: `docs/api_reference.md`
- Modify: `docs/architecture.md`
- Modify: `docs/acceptance-checklist.md`
- Modify: `docs/release-alignment.md`
- Modify: `docs/release-checklist.md`
- Modify: `CHANGELOG.md`
- Modify: `moon.mod`

- [ ] **Step 1: Document semantics and examples**

Document the new public types, method signatures, best-effort batch behavior,
checkpoint-based atomic compensation pattern, audit-vs-history distinction,
and order example command. State that `0.2.0` is the engineering-expansion
release and that the package remains dependency-free.

- [ ] **Step 2: Align release metadata**

Change `moon.mod`, README, changelog, and release documents to `0.2.0`. Do
not claim Mooncakes publication until the package is actually published and
the API reports the new version.

### Task 9: Full verification and release

- [ ] **Step 1: Run local verification**

Run:

```powershell
moon version --all
moon fmt --check
moon info
moon check --deny-warn --target all
moon test --deny-warn
moon run examples/order_workflow
moon run benchmarks
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test_verify_acceptance_output.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_acceptance.ps1 -SkipMooncakes
moon publish --dry-run
```

- [ ] **Step 2: Review source and generated output**

Use `git diff --check`, count effective `.mbt` lines excluding `_build`, run
`git ls-files _build`, inspect `moon info`, and confirm no generated files are
staged.

- [ ] **Step 3: Commit the implementation**

Create a commit named `feat: expand workflow runtime for final acceptance`
only after all local checks pass.

- [ ] **Step 4: Push and publish**

Push the final commit to GitHub and GitLink `main` and `master`, run
`moon publish`, and poll the Mooncakes API until `latest_version` is `0.2.0`
and `build_status` is `success`.

- [ ] **Step 5: Verify remote parity**

Run `git ls-remote --symref` for both remotes and confirm `HEAD`, `main`, and
`master` point to the final commit, then verify GitHub Actions completed with
success for that commit.

## Plan Self-Review

- Spec coverage: every design goal has a task; compatibility, batch semantics,
  snapshot boundaries, metrics, audit, example, benchmark, docs, CI, release,
  and remote verification are explicitly covered.
- Placeholder scan: no `TODO`, `TBD`, or unspecified implementation step is
  required; all commands and expected outcomes are named.
- Type consistency: `EngineSnapshot[S, E, Ctx]`, `DispatchOutcome[E]`,
  `BatchReport[E]`, `ExecutionMetrics`, and `AuditRecord[S, E]` are used with
  the same names and fields throughout the plan.
- Scope: the implementation remains a single cohesive runtime expansion and
  does not introduce a hierarchical state-machine rewrite.
