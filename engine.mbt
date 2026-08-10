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
/// Returns the successful transition history.
pub fn[S, E, Ctx] Engine::history(
  self : Engine[S, E, Ctx],
) -> Array[TransitionRecord[S, E]] {
  self.history_entries.copy()
}

///|
/// Returns the most recent transition error, if any.
pub fn[S, E, Ctx] Engine::last_error(
  self : Engine[S, E, Ctx],
) -> TransitionError? {
  self.last_error_value
}

///|
fn[S, E, Ctx] fail_with(
  engine : Engine[S, E, Ctx],
  current : S,
  event : E,
  err : TransitionError,
) -> Result[Unit, TransitionError] {
  engine.last_error_value = Some(err)
  engine.record_failure(current, event, err)
  Err(err)
}

///|
/// Sends an event to the state machine engine to trigger a transition.
pub fn[S : Hash + Eq, E : Hash + Eq, Ctx] Engine::send(
  self : Engine[S, E, Ctx],
  event : E,
) -> Result[Unit, String] {
  match self.try_send(event) {
    Ok(_) => Ok(())
    Err(err) => Err(format_transition_error(err))
  }
}

///|
/// Attempts a transition and returns a structured transition error on failure.
pub fn[S : Hash + Eq, E : Hash + Eq, Ctx] Engine::try_send(
  self : Engine[S, E, Ctx],
  event : E,
) -> Result[Unit, TransitionError] {
  match self.build_error {
    Some(err) => return fail_with(self, self.current_state, event, err)
    None => ()
  }

  let current = self.current_state
  match self.transitions.get(current) {
    None => fail_with(self, current, event, NoTransitionsForCurrentState)
    Some(state_map) =>
      match state_map.get(event) {
        None => fail_with(self, current, event, EventNotHandledInCurrentState)
        Some(next_state) => {
          let guard_fn_opt = match self.guards.get(current) {
            Some(state_guards) => state_guards.get(event)
            None => None
          }
          let action_fn_opt = match self.actions.get(current) {
            Some(state_actions) => state_actions.get(event)
            None => None
          }
          let used_guard = guard_fn_opt is Some(_)
          let used_action = action_fn_opt is Some(_)
          let allowed = match guard_fn_opt {
            Some(guard_fn) => guard_fn(current, event, self.context)
            None => true
          }

          if !allowed {
            return fail_with(self, current, event, GuardRejected)
          }

          match action_fn_opt {
            Some(action_fn) =>
              self.context = action_fn(current, event, self.context)
            None => ()
          }

          match self.on_exit.get(current) {
            Some(cb) => {
              self.record_hook()
              cb(current, event, self.context)
            }
            None => ()
          }

          self.current_state = next_state

          match self.on_enter.get(next_state) {
            Some(cb) => {
              self.record_hook()
              cb(next_state, event, self.context)
            }
            None => ()
          }

          let history_index = self.history_entries.length()
          self.history_entries.push({
            from: current,
            event,
            to: next_state,
            used_guard,
            used_action,
          })
          self.record_success(current, event, next_state, history_index)
          self.last_error_value = None
          Ok(())
        }
      }
  }
}
