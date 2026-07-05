///|
fn main {
  println("--- Vending Machine Example ---")

  // Context holds the coin balance
  let builder : @fsm.Builder[String, String, Int] = @fsm.Builder::new()
    .transition("Idle", "InsertCoin", "Counting")
    // If balance >= 10, unlock
    .transition_if("Counting", "CheckBalance", "Unlocked", fn(_s, _e, ctx) {
      ctx >= 10
    })
    // If balance < 10, go back to idle waiting for more
    .transition_if("Counting", "CheckBalance", "Idle", fn(_s, _e, ctx) {
      ctx < 10
    })
    .transition("Unlocked", "Dispense", "Idle")

  let _engine = builder.build("Idle", 0)

  // Note: Since context is immutable via value in MoonBit currently unless using mut, 
  // in a real app context would be a struct with mutable fields.
  println("Mermaid Diagram:\n" + @fsm.to_mermaid(builder))
}
