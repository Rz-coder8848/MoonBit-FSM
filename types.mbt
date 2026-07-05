///|
/// A guard function that determines if a transition is allowed.
/// It takes the current state, the event, and the context.
pub type Guard[S, E, Ctx] = (S, E, Ctx) -> Bool

///|
/// A callback function that executes during a state lifecycle hook.
pub type Callback[S, E, Ctx] = (S, E, Ctx) -> Unit

///|
/// A transition definition specifying the source state, the event that triggers it,
/// and the target state it transitions to.
pub(all) struct Transition[S, E, Ctx] {
  from : S
  to : S
  event : E
  guard_cond : Guard[S, E, Ctx]?
}

///|
/// Core configuration for a state machine builder.
pub(all) struct EngineConfig[S, E, Ctx] {
  transitions : Array[Transition[S, E, Ctx]]
  on_enter : Map[S, Callback[S, E, Ctx]]
  on_exit : Map[S, Callback[S, E, Ctx]]
}

///|
/// The runtime instance of the Finite State Machine.
pub(all) struct Engine[S, E, Ctx] {
  transitions : Map[S, Map[E, S]]
  guards : Map[S, Map[E, Guard[S, E, Ctx]]]
  on_enter : Map[S, Callback[S, E, Ctx]]
  on_exit : Map[S, Callback[S, E, Ctx]]
  mut current_state : S
  mut context : Ctx
}
