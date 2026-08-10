///|
/// A Builder for constructing finite state machines declaratively.
pub(all) struct Builder[S, E, Ctx] {
  config : EngineConfig[S, E, Ctx]
}

///|
/// Creates a new FSM Builder.
pub fn[S : Hash + Eq, E, Ctx] Builder::new() -> Builder[S, E, Ctx] {
  { config: { transitions: [], on_enter: Map([]), on_exit: Map([]) } }
}

///|
/// Adds a transition from one state to another triggered by an event.
pub fn[S, E, Ctx] Builder::transition(
  self : Builder[S, E, Ctx],
  from : S,
  event : E,
  to : S,
) -> Builder[S, E, Ctx] {
  self.config.transitions.push({
    from,
    to,
    event,
    guard_cond: None,
    action: None,
  })
  self
}

///|
/// Adds a transition with a guard condition.
pub fn[S, E, Ctx] Builder::transition_if(
  self : Builder[S, E, Ctx],
  from : S,
  event : E,
  to : S,
  guard_cond : Guard[S, E, Ctx],
) -> Builder[S, E, Ctx] {
  self.config.transitions.push({
    from,
    to,
    event,
    guard_cond: Some(guard_cond),
    action: None,
  })
  self
}

///|
/// Adds a transition with a context-updating action.
pub fn[S, E, Ctx] Builder::transition_do(
  self : Builder[S, E, Ctx],
  from : S,
  event : E,
  to : S,
  action : TransitionAction[S, E, Ctx],
) -> Builder[S, E, Ctx] {
  self.config.transitions.push({
    from,
    to,
    event,
    guard_cond: None,
    action: Some(action),
  })
  self
}

///|
/// Adds a guarded transition with a context-updating action.
pub fn[S, E, Ctx] Builder::transition_if_do(
  self : Builder[S, E, Ctx],
  from : S,
  event : E,
  to : S,
  guard_cond : Guard[S, E, Ctx],
  action : TransitionAction[S, E, Ctx],
) -> Builder[S, E, Ctx] {
  self.config.transitions.push({
    from,
    to,
    event,
    guard_cond: Some(guard_cond),
    action: Some(action),
  })
  self
}

///|
/// Registers a callback to be executed when entering a specific state.
pub fn[S : Hash + Eq, E, Ctx] Builder::on_enter(
  self : Builder[S, E, Ctx],
  state : S,
  callback : Callback[S, E, Ctx],
) -> Builder[S, E, Ctx] {
  self.config.on_enter.set(state, callback)
  self
}

///|
/// Registers a callback to be executed when exiting a specific state.
pub fn[S : Hash + Eq, E, Ctx] Builder::on_exit(
  self : Builder[S, E, Ctx],
  state : S,
  callback : Callback[S, E, Ctx],
) -> Builder[S, E, Ctx] {
  self.config.on_exit.set(state, callback)
  self
}

///|
fn[S : Hash + Eq, V] ensure_state_map(
  store : Map[S, V],
  key : S,
  default_value : V,
) -> V {
  match store.get(key) {
    Some(existing) => existing
    None => {
      store.set(key, default_value)
      default_value
    }
  }
}

///|
/// Builds the FSM runtime engine starting at the given state.
pub fn[S : Hash + Eq, E : Hash + Eq, Ctx] Builder::build(
  self : Builder[S, E, Ctx],
  initial_state : S,
  initial_context : Ctx,
) -> Engine[S, E, Ctx] {
  let transitions = Map([])
  let guards = Map([])
  let actions = Map([])
  let duplicate_transitions = duplicate_transition_entries(self)

  for t in self.config.transitions {
    let state_map = ensure_state_map(transitions, t.from, Map([]))
    if state_map.contains(t.event) {
      continue
    }

    state_map.set(t.event, t.to)

    match t.guard_cond {
      Some(guard_cond) => {
        let state_guards = ensure_state_map(guards, t.from, Map([]))
        state_guards.set(t.event, guard_cond)
      }
      None => ()
    }

    match t.action {
      Some(action) => {
        let state_actions = ensure_state_map(actions, t.from, Map([]))
        state_actions.set(t.event, action)
      }
      None => ()
    }
  }

  {
    transitions,
    guards,
    actions,
    on_enter: self.config.on_enter,
    on_exit: self.config.on_exit,
    history_entries: [],
    audit_entries: [],
    metrics_value: {
      attempted: 0,
      successful: 0,
      rejected: 0,
      guard_rejected: 0,
      unknown_event: 0,
      no_outgoing_state: 0,
      duplicate_configuration: 0,
      invalid_configuration: 0,
      lifecycle_hooks: 0,
    },
    current_state: initial_state,
    context: initial_context,
    last_error_value: None,
    build_error: if duplicate_transitions.length() > 0 {
      Some(DuplicateTransitionDefinition)
    } else {
      None
    },
  }
}
