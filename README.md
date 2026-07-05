# MoonBit-FSM

`moon-fsm` is a MoonBit finite state machine library for projects that need a
small, readable transition model instead of a framework-heavy runtime. It
focuses on three practical pieces of behavior:

- typed state and event transitions
- guard-based transition validation
- Mermaid export for quick documentation and review

This repository is being maintained as a CCF x MoonBit OSC2026 accepted
project. The competition-related work in this repository is the engineering
increment after 2026-04-29: API cleanup, examples, tests, CI, acceptance
checks, and Mooncakes release preparation.

## Why This Library

Finite state machines are a good fit when business rules or interactive flows
need to stay auditable. Typical use cases include:

- command or workflow orchestration
- game or simulation agents
- UI or device state management
- teaching materials for MoonBit control-flow patterns

The library keeps the runtime small and pushes most of the complexity into a
declarative `Builder`, so state diagrams and transition reviews stay easy to
follow in code review.

## Package Identity

- Module name: `Rz-coder8848/moon-fsm`
- Package version: `0.1.0`
- Repository: [Rz-coder8848/MoonBit-FSM](https://github.com/Rz-coder8848/MoonBit-FSM)
- Mirror: [Douj/moon-fsm](https://gitlink.org.cn/Douj/moon-fsm)
- License: Apache-2.0
- Mooncakes: pending publication during acceptance completion

## Install

```bash
moon add Rz-coder8848/moon-fsm
```

## Minimal Example

```moonbit
let builder : @fsm.Builder[String, String, Int] = @fsm.Builder::new()
  .transition("Idle", "InsertCoin", "Counting")
  .transition_if("Counting", "CheckBalance", "Unlocked", fn(_s, _e, ctx) { ctx >= 10 })
  .transition_if("Counting", "CheckBalance", "Idle", fn(_s, _e, ctx) { ctx < 10 })
  .transition("Unlocked", "Dispense", "Idle")

let engine = builder.build("Idle", 0)

ignore(engine.send("InsertCoin"))
```

## Core API

- `Builder::new()` creates a state machine description.
- `transition()` adds a normal transition.
- `transition_if()` adds a guarded transition.
- `on_enter()` and `on_exit()` register lifecycle callbacks.
- `build()` materializes an `Engine`.
- `validate()` reports states that are unreachable from the chosen initial
  state.
- `to_mermaid()` exports the configured transitions as Mermaid text.

API details live in [docs/api_reference.md](docs/api_reference.md).

## Examples

These examples are intended to be runnable review artifacts rather than
marketing demos:

- `moon run examples/traffic_light`
- `moon run examples/vending_machine`
- `moon run examples/game_npc`
- `moon run cmd/fsm-cli`

## Verification

Local verification used for this repository:

```bash
moon info
moon fmt --check
moon check
moon test
powershell -ExecutionPolicy Bypass -File scripts/verify_acceptance.ps1 -SkipMooncakes
```

`scripts/verify_acceptance.ps1` is the acceptance gate for repository
completeness. It checks required files, MoonBit commands, tracked build
artifacts, and Mooncakes visibility.

## Documentation

- [Architecture](docs/architecture.md)
- [API reference](docs/api_reference.md)
- [Acceptance checklist](docs/acceptance-checklist.md)
- [Release checklist](docs/release-checklist.md)

## Notes For Reviewers

- The repository keeps both GitHub and GitLink public so acceptance reviewers
  can inspect commit history on either platform.
- Generated build output is intentionally excluded from version control.
- The checked-in competition material is [申报书.md](申报书.md); the proposal PDF is
  not regenerated in this completion pass.

## Contributing

Small, reviewable changes are preferred. Before opening a PR, run the same
local verification commands listed above and keep examples executable.
