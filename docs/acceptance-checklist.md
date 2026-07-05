# Acceptance Checklist

This checklist is written for the OSC2026 acceptance phase and mirrors the
public evidence a reviewer can verify from the repository itself.

## Repository

- Public source repository is available on GitHub and mirrored on GitLink.
- `README.md` explains the project goal, install path, examples, and
  verification commands.
- `LICENSE` is present and uses an OSI-approved license.
- `CHANGELOG.md` records post-2026-04-29 maintenance work.

## Engineering Quality

- `moon fmt --check` passes.
- `moon check` passes.
- `moon test` passes.
- CI runs the same baseline checks on pushes to `main`.
- `_build/` and other generated outputs are not tracked.

## Usability

- At least one minimal library example is documented in `README.md`.
- Runnable examples exist under `examples/`.
- `cmd/fsm-cli` provides a simple command-line demonstration.
- `docs/api_reference.md` and `docs/architecture.md` describe the public API and
  internal structure.

## Release Readiness

- Package identity matches `Rz-coder8848/moon-fsm`.
- Mooncakes publish steps are documented in `docs/release-checklist.md`.
- `scripts/verify_acceptance.ps1` reports Mooncakes visibility once published.
