# Release Alignment

This document records the acceptance remediation release alignment for
`Rz-coder8848/moon-fsm`.

## Version Timeline

- `0.1.0`: initial Mooncakes publication and acceptance baseline.
- `0.1.1`: first OSC2026 re-review remediation release with workflow-oriented
  features, expanded validation, refreshed CI, and repository alignment fixes.
- `0.1.2`: final-acceptance hardening release with four-domain benchmark data,
  deterministic runner checks, and expanded boundary regression tests.
- `0.2.0`: workflow-runtime expansion release with checkpoint/restore,
  best-effort batch dispatch, metrics, audit records, a 32-case corpus, and an
  order workflow example.
- `0.2.1`: MoonBit 0.10.3 compatibility patch for executable package
  configuration; runtime behavior is unchanged.

## Public Endpoints

- GitHub: `https://github.com/Rz-coder8848/MoonBit-FSM`
- GitLink: `https://gitlink.org.cn/Douj/moon-fsm`
- Mooncakes API: `https://mooncakes.io/api/v0/modules/Rz-coder8848/moon-fsm`

## Alignment Rules

- `moon.mod` version, `README.md` package version, and Mooncakes latest version
  must match before final acceptance submission.
- GitHub and GitLink should both point reviewers to the same `main` branch
  contents.
- CI must run `moon fmt --check`, `moon info`, `moon check --deny-warn --target all`,
  and `moon test --deny-warn --target all` on the current repository state.
