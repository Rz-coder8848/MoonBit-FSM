///|
/// Retrieves the current state of the engine.
pub fn[S, E, Ctx] Engine::state(self : Engine[S, E, Ctx]) -> S {
  self.current_state
}

///|
/// Retrieves the current context of the engine.
pub fn[S, E, Ctx] Engine::context(self : Engine[S, E, Ctx]) -> Ctx {
  self.context
}

///|
/// Sends an event to the state machine engine to trigger a transition.
pub fn[S : Hash + Eq, E : Hash + Eq, Ctx] Engine::send(
  self : Engine[S, E, Ctx],
  event : E,
) -> Result[Unit, String] {
  let current = self.current_state
  match self.transitions.get(current) {
    None => Err("No transitions defined for current state")
    Some(state_map) =>
      match state_map.get(event) {
        None => Err("Event not handled in current state")
        Some(next_state) => {
          // Check guard condition if exists
          let allowed = match self.guards.get(current) {
            Some(evt_guards) =>
              match evt_guards.get(event) {
                Some(guard_cond) => guard_cond(current, event, self.context)
                None => true
              }
            None => true
          }

          if !allowed {
            return Err("Transition blocked by guard condition")
          }

          // Execute on_exit for current state
          match self.on_exit.get(current) {
            Some(cb) => cb(current, event, self.context)
            None => ()
          }

          self.current_state = next_state

          // Execute on_enter for next state
          match self.on_enter.get(next_state) {
            Some(cb) => cb(next_state, event, self.context)
            None => ()
          }

          Ok(())
        }
      }
  }
}
