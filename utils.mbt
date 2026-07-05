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
