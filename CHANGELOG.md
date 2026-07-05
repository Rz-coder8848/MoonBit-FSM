# Changelog

All notable project changes are documented here. For OSC2026 acceptance review,
the most relevant work is the repository maintenance and release-hardening after
2026-04-29.

## [2026-07-05] Acceptance Completion Pass

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
