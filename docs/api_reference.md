# API Reference

## Types

### `Guard[S, E, Ctx]`

Predicate used by guarded transitions. It receives the current state, event,
and context, then returns `Bool`.

### `Callback[S, E, Ctx]`

Lifecycle callback used by `on_enter` and `on_exit`.

### `TransitionAction[S, E, Ctx]`

Action executed during a successful transition. It receives the current state,
event, and context, then returns the next context value.

### `TransitionError`

Structured runtime errors:

- `NoTransitionsForCurrentState`
- `EventNotHandledInCurrentState`
- `GuardRejected`
- `DuplicateTransitionDefinition`
- `InvalidConfiguration`

### `TransitionRecord[S, E]`

Successful transition history entry containing:

- `from`
- `event`
- `to`
- `used_guard`
- `used_action`

### `DuplicateTransition[S, E]`

Structured duplicate-definition marker for a repeated `(state, event)` pair.

### `ValidationReport[S, E]`

Structured validation output containing:

- `unreachable_states`
- `dead_end_states`
- `duplicate_transitions`
- `states_without_outgoing_edges`

### `Builder[S, E, Ctx]`

Configuration object used to define the state machine before runtime.

### `Engine[S, E, Ctx]`

Runtime object that stores the current state, context, transition tables,
history, and the most recent runtime error.

## Builder API

### `Builder::new()`

Create an empty builder.

### `transition(from, event, to)`

Register a normal transition.

### `transition_if(from, event, to, guard_cond)`

Register a transition guarded by `guard_cond`.

### `transition_do(from, event, to, action)`

Register a transition that updates context during a successful state change.

### `transition_if_do(from, event, to, guard_cond, action)`

Register a guarded transition that also updates context.

### `on_enter(state, callback)`

Register a callback that runs after the engine enters `state`.

### `on_exit(state, callback)`

Register a callback that runs before the engine leaves `state`.

### `build(initial_state, initial_context)`

Create an `Engine` from the configured transitions and hooks. Duplicate
transition definitions are preserved for validation and surfaced as a runtime
configuration error when events are executed.

## Engine API

### `state()`

Return the current state.

### `context()`

Return the current context value.

### `history()`

Return successful `TransitionRecord` entries in execution order.

### `last_error()`

Return the most recent `TransitionError`, if any.

### `try_send(event)`

Attempt to process one event and return `Result[Unit, TransitionError]`.

Recommended when workflow code needs structured handling of guard failures,
missing events, or invalid builder configuration.

### `send(event)`

Compatibility wrapper around `try_send(event)` that returns
`Result[Unit, String]`.

Recommended only when older call sites expect string errors.

## Validation and Helper Functions

### `validate(builder, initial_state)`

Return the list of unreachable states for backwards compatibility.

### `validate_report(builder, initial_state)`

Return a `ValidationReport` for acceptance review and richer diagnostics.

### `duplicate_transition_entries(builder)`

Return duplicate `(state, event)` definitions discovered in a builder.

### `to_mermaid(builder)`

Export builder transitions as Mermaid `stateDiagram-v2` text. Guarded and
action-bearing transitions are annotated inline.

### `format_transition_error(err)`

Convert a structured `TransitionError` into a stable public string.
