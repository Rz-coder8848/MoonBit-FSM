///|
/// Dispatches events in order and records every success or rejection.
pub fn[S : Hash + Eq, E : Hash + Eq, Ctx] Engine::try_send_all(
  self : Engine[S, E, Ctx],
  events : Array[E],
) -> BatchReport[E] {
  let outcomes = []
  let mut successful = 0
  let mut rejected = 0

  for event in events {
    match self.try_send(event) {
      Ok(_) => {
        successful += 1
        outcomes.push({ event, success: true, error: None })
      }
      Err(err) => {
        rejected += 1
        outcomes.push({ event, success: false, error: Some(err) })
      }
    }
  }

  { outcomes, successful, rejected, complete: rejected == 0 }
}
