# Changelog

All notable project changes are documented here. For OSC2026 acceptance review,
the most relevant work is the repository maintenance and release-hardening after
2026-04-29.

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
