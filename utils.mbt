///|
/// Assert a condition, panics if false (useful for internal engine invariants).
pub fn assert_invariant(cond : Bool, _msg : String) -> Unit {
  if !cond {
    panic()
  }
}

///|
/// Helper to format transition logs.
pub fn[S : Show, E : Show] format_transition_log(
  from : S,
  event : E,
  to : S,
) -> String {
  "Transition: \{from} --(\{event})--> \{to}"
}

///|
/// Converts a structured transition error into a stable public string.
pub fn format_transition_error(err : TransitionError) -> String {
  match err {
    NoTransitionsForCurrentState => "No transitions defined for current state"
    EventNotHandledInCurrentState => "Event not handled in current state"
    GuardRejected => "Transition blocked by guard condition"
    DuplicateTransitionDefinition => "Duplicate transition definition detected"
    InvalidConfiguration => "Invalid state machine configuration"
  }
}
