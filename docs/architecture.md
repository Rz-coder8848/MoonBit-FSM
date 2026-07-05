# MoonBit-FSM Architecture

## Overview

`moon-fsm` is organized as a small library with a straightforward flow:

1. describe transitions with `Builder`
2. validate graph reachability with `validate`
3. instantiate an `Engine`
4. drive transitions with `send`
5. export diagrams with `to_mermaid` when documentation is needed

The code is intentionally compact so examples and tests stay readable during
acceptance review.

## Main Components

### Builder

`Builder[S, E, Ctx]` is the declarative layer. It stores transition
descriptions, guarded transitions, and lifecycle hooks before any runtime state
exists.

Responsibilities:

- collect transitions
- collect guarded transitions
- register `on_enter` and `on_exit` callbacks
- materialize the runtime maps used by `Engine`

### Engine

`Engine[S, E, Ctx]` is the runtime layer. It stores:

- current state
- current context
- transition lookup tables
- optional guard lookup tables
- lifecycle callback maps

`send(event)` performs one transition attempt:

1. look up transitions for the current state
2. reject unknown events
3. evaluate any guard for the `(state, event)` pair
4. run `on_exit`
5. update `current_state`
6. run `on_enter`

### Validator

`validate(builder, initial_state)` performs a reachability pass over the
declared transitions. It is useful when state machines are assembled from
configuration-like code and reviewers want a quick sanity check before runtime.

### Mermaid Exporter

`to_mermaid(builder)` converts the builder transitions into Mermaid text. This
keeps the documentation path close to the code path: examples can generate the
same transition view that appears in reviews or project notes.

## Data Model

The library uses generic parameters:

- `S` for state identifiers
- `E` for events
- `Ctx` for user-defined context

This keeps the public API flexible enough for string-based teaching examples and
for richer typed state machines in real applications.

## Design Constraints

- No external runtime dependencies.
- Public examples should remain short enough to audit quickly.
- Generated build output is not part of the reviewed source tree.
- The library favors explicit transition tables over hidden control flow.
