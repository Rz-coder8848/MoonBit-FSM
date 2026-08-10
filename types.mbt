///|
/// A guard function that determines if a transition is allowed.
pub type Guard[S, E, Ctx] = (S, E, Ctx) -> Bool

///|
/// A callback function that executes during a state lifecycle hook.
pub type Callback[S, E, Ctx] = (S, E, Ctx) -> Unit

///|
/// A transition action that returns the next context value for a transition.
pub type TransitionAction[S, E, Ctx] = (S, E, Ctx) -> Ctx

///|
/// A transition definition specifying the source state, event, and target state.
pub(all) struct Transition[S, E, Ctx] {
  from : S
  to : S
  event : E
  guard_cond : Guard[S, E, Ctx]?
  action : TransitionAction[S, E, Ctx]?
}

///|
/// A duplicate transition entry discovered during validation.
pub(all) struct DuplicateTransition[S, E] {
  from : S
  event : E
} derive(Eq)

///|
/// A record of a successful transition execution.
pub(all) struct TransitionRecord[S, E] {
  from : S
  event : E
  to : S
  used_guard : Bool
  used_action : Bool
} derive(Eq)

///|
/// Structured transition errors returned by the enhanced runtime API.
pub(all) enum TransitionError {
  NoTransitionsForCurrentState
  EventNotHandledInCurrentState
  GuardRejected
  DuplicateTransitionDefinition
  InvalidConfiguration
} derive(Eq)

///|
/// The result of one event attempt in an ordered batch dispatch.
pub(all) struct DispatchOutcome[E] {
  event : E
  success : Bool
  error : TransitionError?
}

///|
/// Summary of an ordered, best-effort event batch.
pub(all) struct BatchReport[E] {
  outcomes : Array[DispatchOutcome[E]]
  successful : Int
  rejected : Int
  complete : Bool
}

///|
/// Runtime counters for successful and rejected event attempts.
pub(all) struct ExecutionMetrics {
  mut attempted : Int
  mut successful : Int
  mut rejected : Int
  mut guard_rejected : Int
  mut unknown_event : Int
  mut no_outgoing_state : Int
  mut duplicate_configuration : Int
  mut invalid_configuration : Int
  mut lifecycle_hooks : Int
} derive(Eq)

///|
/// Complete audit entry for one event attempt.
pub(all) struct AuditRecord[S, E] {
  from : S
  to : S
  event : E
  success : Bool
  error : TransitionError?
  history_index : Int?
}

///|
/// A restorable boundary for an engine's observable runtime state.
pub(all) struct EngineSnapshot[S, E, Ctx] {
  state : S
  context : Ctx
  mut history_entries : Array[TransitionRecord[S, E]]
  audit_entries : Array[AuditRecord[S, E]]
  metrics : ExecutionMetrics
  last_error : TransitionError?
}

///|
/// Structured validation output for repository acceptance and reviewer audits.
pub(all) struct ValidationReport[S, E] {
  unreachable_states : Array[S]
  dead_end_states : Array[S]
  duplicate_transitions : Array[DuplicateTransition[S, E]]
  states_without_outgoing_edges : Array[S]
} derive(Eq)

///|
/// Core configuration for a state machine builder.
pub(all) struct EngineConfig[S, E, Ctx] {
  transitions : Array[Transition[S, E, Ctx]]
  on_enter : Map[S, Callback[S, E, Ctx]]
  on_exit : Map[S, Callback[S, E, Ctx]]
}

///|
/// The runtime instance of the state machine.
pub(all) struct Engine[S, E, Ctx] {
  transitions : Map[S, Map[E, S]]
  guards : Map[S, Map[E, Guard[S, E, Ctx]]]
  actions : Map[S, Map[E, TransitionAction[S, E, Ctx]]]
  on_enter : Map[S, Callback[S, E, Ctx]]
  on_exit : Map[S, Callback[S, E, Ctx]]
  mut history_entries : Array[TransitionRecord[S, E]]
  mut audit_entries : Array[AuditRecord[S, E]]
  mut metrics_value : ExecutionMetrics
  mut current_state : S
  mut context : Ctx
  mut last_error_value : TransitionError?
  build_error : TransitionError?
}

///|
/// FSM engine configuration parameters.
pub(all) struct EngineOptions {
  strict_mode : Bool
  max_history : Int
}
