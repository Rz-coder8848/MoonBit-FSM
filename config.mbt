///|
/// FSM engine configuration parameters.
pub(all) struct EngineOptions {
  strict_mode : Bool
  max_history : Int
}

///|
/// Provides default engine options.
pub fn EngineOptions::default() -> EngineOptions {
  { strict_mode: true, max_history: 10 }
}
