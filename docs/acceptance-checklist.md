# Acceptance Checklist

This checklist mirrors the public evidence a reviewer can verify from the
repository itself for the OSC2026 acceptance phase.

## Repository

- Public source repository is available on GitHub and mirrored on GitLink.
- `README.md` explains project positioning, install path, verification
  commands, and workflow-oriented capabilities.
- `LICENSE` is present and uses an OSI-approved license.
- `CHANGELOG.md` records the remediation release work after 2026-04-29.
- `docs/release-alignment.md` records GitHub, GitLink, and Mooncakes alignment.

## Engineering Quality

- `moon fmt --check` passes.
- `moon info` passes.
- `moon check --deny-warn --target all` passes.
- `moon test --deny-warn --target all` passes.
- CI runs the same baseline checks on `main` across Linux, macOS, and Windows.
- `_build/` and other generated outputs are not tracked.

## Usability

- Runnable examples exist under `examples/`, including a composite approval
  workflow and an order workflow with batch compensation.
- `benchmarks/data/workflow_cases.csv` provides a checked-in, reproducible
  32-case scenario corpus across four workflow domains.
- `moon run benchmarks` verifies the corpus against expected states, accepted
  and rejected events, transition history counts, and audit-entry counts.
- Runtime tests cover actions, structured errors, snapshots, best-effort
  batches, metrics, audit isolation, lifecycle hooks, and boundary behavior.
- `cmd/fsm-cli` provides a command-line demonstration.
- `docs/api_reference.md` and `docs/architecture.md` describe the public API,
  runtime flow, error model, and validator report.
- Mermaid output exposes guards and actions for reviewer inspection.

## Release Readiness

- Package identity matches `Rz-coder8848/moon-fsm`.
- The current MoonBit 0.10.3 compatibility release is `0.2.1`, following the
  `0.2.0` workflow-runtime expansion.
- Mooncakes publish steps are documented in `docs/release-checklist.md`.
- `scripts/verify_acceptance.ps1` checks CI coverage, metadata alignment, and
  Mooncakes version parity when publication verification is enabled.
