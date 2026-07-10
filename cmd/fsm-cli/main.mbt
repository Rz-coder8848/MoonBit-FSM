///|
fn main {
  println("MoonBit FSM CLI v0.2.1")

  let builder : @fsm.Builder[String, String, Int] = @fsm.Builder::new()
    .transition_do("Locked", "Coin", "Unlocked", fn(_s, _e, ctx) { ctx + 1 })
    .transition("Unlocked", "Push", "Locked")

  let engine = builder.build("Locked", 0)
  println("Initial state: \{engine.state()}")

  match engine.try_send("Coin") {
    Ok(_) => {
      println("Event: Coin -> New state: \{engine.state()}")
      println("Context after action: \{engine.context()}")
    }
    Err(err) => println("Error: \{@fsm.format_transition_error(err)}")
  }

  println("History entries: \{engine.history().length()}")
}
