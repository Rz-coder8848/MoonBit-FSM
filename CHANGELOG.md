# Changelog

## 0.3.0 - 2026-08-16

This release expands the reusable workflow surface beyond the original FSM
runtime in response to OSC2026 engineering-scope feedback.

- Added bounded retry policies, rejection budgets, graph analysis, and risk reports.
- Added operational journals with severity, acknowledgement, ticket queries,
  audit ingestion, SLA evaluation, and closure-gate helpers.
- Added support-ticket and production incident-response runbooks with
  escalation, rollback, handover, and postmortem paths.
- Expanded the deterministic benchmark corpus from 32 to 44 scenarios and the
  executable test suite to 52 cases.

All notable project changes are documented here. For OSC2026 acceptance review,
the most relevant work is the repository maintenance and release-hardening after
2026-04-29.

## [0.2.1] - 2026-08-16

### Fixed

- replaced the MoonBit 0.10.4-only `pkgtype` declarations with the
  MoonBit 0.10.3-compatible `options("is-main": true)` form
- verified all executable examples, benchmark packages, and the CLI under
  MoonBit 0.10.3
- kept the `0.2.0` workflow-runtime behavior unchanged while aligning the
  published package with the competition toolchain

## [0.2.0] - 2026-08-11

### Changed

- expanded the runtime with complete engine checkpoints and compensation-ready
  restore
- added ordered best-effort batch dispatch with per-event outcomes
- added execution metrics and audit records for accepted and rejected attempts
- added an executable order workflow example with guards, actions, lifecycle
  hooks, error branches, and Mermaid export
- expanded the deterministic workflow corpus from 15 to 32 cases and asserted
  audit coverage for every event attempt
- added focused regression tests for snapshots, batches, metrics, audit
  isolation, and structured failure classification
- updated CI and acceptance scripts to run and verify the expanded public
  surface

## [0.1.1] - 2026-07-10

### Changed

- repositioned the library as an auditable workflow-oriented FSM component
- added structured transition errors and runtime history inspection
- added transition actions and validator reports
- added a composite approval workflow example and expanded test coverage
- refreshed CI to use MoonBit 0.10.3-compatible verification commands
- aligned repository docs with the published Mooncakes release story
- prepared the repository for the OSC2026 re-review remediation release

## [0.1.2] - 2026-08-11

### Changed

- published the final-acceptance hardening release for OSC2026
- added a reproducible four-domain workflow benchmark corpus and runner
- added boundary regression coverage for empty machines, dead ends, blocked
  guards, unknown events, duplicate definitions, history ordering, and empty
  Mermaid exports
- removed the duplicate `(state, event)` design from the vending machine example
- added dedicated tests for lifecycle hook execution order
- added dedicated tests for Mermaid export annotations
- cleaned up empty map literals to pass strict warning gates on newer MoonBit toolchains

## [0.1.0] - 2026-07-05

### Changed

- rewrote the README to focus on verifiable engineering information
- added acceptance and release checklists
- added a repository-level acceptance verification script
- prepared the repository for current `moon.mod` / `moon.pkg` metadata
- aligned package metadata with current Mooncakes publish requirements
- removed generated build output from version control
- updated CI to run the acceptance verification gate

## [2026-06-30] Release Preparation

### Changed

- updated CI and repository-facing documents for the acceptance phase
- aligned the codebase with MoonBit 0.10-era syntax expectations

## [2026-06-11] Initial Competition Baseline

### Added

- core builder, engine, validator, and exporter modules
- runnable CLI and example programs
- initial unit tests for transitions and validation
