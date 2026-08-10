///|
/// Creates an empty execution counter set.
pub fn ExecutionMetrics::zero() -> ExecutionMetrics {
  {
    attempted: 0,
    successful: 0,
    rejected: 0,
    guard_rejected: 0,
    unknown_event: 0,
    no_outgoing_state: 0,
    duplicate_configuration: 0,
    invalid_configuration: 0,
    lifecycle_hooks: 0,
  }
}

///|
/// Copies all counters so snapshots and public reads do not share mutable state.
pub fn ExecutionMetrics::copy(self : ExecutionMetrics) -> ExecutionMetrics {
  {
    attempted: self.attempted,
    successful: self.successful,
    rejected: self.rejected,
    guard_rejected: self.guard_rejected,
    unknown_event: self.unknown_event,
    no_outgoing_state: self.no_outgoing_state,
    duplicate_configuration: self.duplicate_configuration,
    invalid_configuration: self.invalid_configuration,
    lifecycle_hooks: self.lifecycle_hooks,
  }
}

///|
fn ExecutionMetrics::record_success(self : ExecutionMetrics) -> Unit {
  self.attempted += 1
  self.successful += 1
}

///|
fn ExecutionMetrics::record_rejection(
  self : ExecutionMetrics,
  err : TransitionError,
) -> Unit {
  self.attempted += 1
  self.rejected += 1
  match err {
    GuardRejected => self.guard_rejected += 1
    EventNotHandledInCurrentState => self.unknown_event += 1
    NoTransitionsForCurrentState => self.no_outgoing_state += 1
    DuplicateTransitionDefinition => self.duplicate_configuration += 1
    InvalidConfiguration => self.invalid_configuration += 1
  }
}

///|
fn ExecutionMetrics::record_hook(self : ExecutionMetrics) -> Unit {
  self.lifecycle_hooks += 1
}

///|
/// Returns a copy of the execution metrics.
pub fn[S, E, Ctx] Engine::metrics(self : Engine[S, E, Ctx]) -> ExecutionMetrics {
  self.metrics_value.copy()
}

///|
/// Returns the complete event-attempt audit log.
pub fn[S, E, Ctx] Engine::audit_log(
  self : Engine[S, E, Ctx],
) -> Array[AuditRecord[S, E]] {
  self.audit_entries.copy()
}

///|
/// Resets metrics and audit entries without changing workflow state.
pub fn[S, E, Ctx] Engine::reset_metrics(self : Engine[S, E, Ctx]) -> Unit {
  self.metrics_value = ExecutionMetrics::zero()
  self.audit_entries.clear()
}

///|
fn[S, E, Ctx] Engine::record_success(
  self : Engine[S, E, Ctx],
  from : S,
  event : E,
  to : S,
  history_index : Int,
) -> Unit {
  self.metrics_value.record_success()
  self.audit_entries.push({
    from,
    to,
    event,
    success: true,
    error: None,
    history_index: Some(history_index),
  })
}

///|
fn[S, E, Ctx] Engine::record_failure(
  self : Engine[S, E, Ctx],
  current : S,
  event : E,
  err : TransitionError,
) -> Unit {
  self.metrics_value.record_rejection(err)
  self.audit_entries.push({
    from: current,
    to: current,
    event,
    success: false,
    error: Some(err),
    history_index: None,
  })
}

///|
fn[S, E, Ctx] Engine::record_hook(self : Engine[S, E, Ctx]) -> Unit {
  self.metrics_value.record_hook()
}
