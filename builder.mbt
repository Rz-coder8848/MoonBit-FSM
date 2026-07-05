///|
/// A Builder for constructing Finite State Machines declaratively.
pub(all) struct Builder[S, E, Ctx] {
  config : EngineConfig[S, E, Ctx]
}

///|
/// Creates a new FSM Builder.
pub fn[S : Hash + Eq, E, Ctx] Builder::new() -> Builder[S, E, Ctx] {
  { config: { transitions: [], on_enter: {}, on_exit: {} } }
}

///|
/// Adds a transition from a specific state to another triggered by an event.
pub fn[S, E, Ctx] Builder::transition(
  self : Builder[S, E, Ctx],
  from : S,
  event : E,
  to : S,
) -> Builder[S, E, Ctx] {
  self.config.transitions.push({ from, to, event, guard_cond: None })
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
  self.config.transitions.push({ from, to, event, guard_cond: Some(guard_cond) })
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
/// Builds the FSM runtime engine starting at the given state.
pub fn[S : Hash + Eq, E : Hash + Eq, Ctx] Builder::build(
  self : Builder[S, E, Ctx],
  initial_state : S,
  initial_context : Ctx,
) -> Engine[S, E, Ctx] {
  let transitions = {}
  let guards = {}

  for t in self.config.transitions {
    let state_map = match transitions.get(t.from) {
      Some(m) => m
      None => {
        let m = {}
        transitions.set(t.from, m)
        m
      }
    }
    state_map.set(t.event, t.to)

    match t.guard_cond {
      Some(g) => {
        let state_guards = match guards.get(t.from) {
          Some(m) => m
          None => {
            let m = {}
            guards.set(t.from, m)
            m
          }
        }
        state_guards.set(t.event, g)
      }
      None => ()
    }
  }

  {
    transitions,
    guards,
    on_enter: self.config.on_enter,
    on_exit: self.config.on_exit,
    current_state: initial_state,
    context: initial_context,
  }
}
