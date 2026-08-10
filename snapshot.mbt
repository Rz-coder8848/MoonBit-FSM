///|
/// Captures the observable runtime state of an engine.
pub fn[S, E, Ctx] Engine::checkpoint(
  self : Engine[S, E, Ctx],
) -> EngineSnapshot[S, E, Ctx] {
  {
    state: self.current_state,
    context: self.context,
    history_entries: self.history_entries.copy(),
    audit_entries: self.audit_entries.copy(),
    metrics: self.metrics_value.copy(),
    last_error: self.last_error_value,
  }
}

///|
/// Restores state, history, audit records, metrics, and the last error.
pub fn[S, E, Ctx] Engine::restore(
  self : Engine[S, E, Ctx],
  snapshot : EngineSnapshot[S, E, Ctx],
) -> Unit {
  self.current_state = snapshot.state
  self.context = snapshot.context
  self.history_entries = snapshot.history_entries.copy()
  self.audit_entries = snapshot.audit_entries.copy()
  self.metrics_value = snapshot.metrics.copy()
  self.last_error_value = snapshot.last_error
}
