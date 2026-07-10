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
  history_entries : Array[TransitionRecord[S, E]]
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
