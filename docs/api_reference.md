# API Reference

## Types

### `Guard[S, E, Ctx]`

Predicate used by guarded transitions. It receives the current state, event,
and context, then returns `Bool`.

### `Callback[S, E, Ctx]`

Lifecycle callback used by `on_enter` and `on_exit`.

### `Builder[S, E, Ctx]`

Configuration object used to define the state machine before runtime.

### `Engine[S, E, Ctx]`

Runtime object that stores the current state, context, and transition tables.

## Builder API

### `Builder::new()`

Create an empty builder.

### `transition(from, event, to)`

Register a normal transition.

### `transition_if(from, event, to, guard_cond)`

Register a transition guarded by `guard_cond`.

### `on_enter(state, callback)`

Register a callback that runs after the engine enters `state`.

### `on_exit(state, callback)`

Register a callback that runs before the engine leaves `state`.

### `build(initial_state, initial_context)`

Create an `Engine` from the configured transitions and hooks.

## Engine API

### `state()`

Return the current state.

### `context()`

Return the current context value.

### `send(event)`

Attempt to process one event.

Returns:

- `Ok(())` when the transition succeeds
- `Err(String)` when the event is unknown, the state has no transitions, or a
  guard rejects the transition

## Helper Functions

### `validate(builder, initial_state)`

Return the list of states that are unreachable from `initial_state`.

### `to_mermaid(builder)`

Export the builder transitions as Mermaid `stateDiagram-v2` text.
