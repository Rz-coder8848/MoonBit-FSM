///|
fn main {
  println("--- Vending Machine Example ---")

  let builder : @fsm.Builder[String, String, Int] = @fsm.Builder::new()
    .transition_do("Idle", "InsertCoin", "Counting", fn(_s, _e, ctx) { ctx + 5 })
    .transition_if("Counting", "CheckBalance", "Unlocked", fn(_s, _e, ctx) {
      ctx >= 10
    })
    .transition_if("Counting", "CheckBalance", "Idle", fn(_s, _e, ctx) {
      ctx < 10
    })
    .transition_do("Unlocked", "Dispense", "Idle", fn(_s, _e, _ctx) { 0 })

  let engine = builder.build("Idle", 0)
  ignore(engine.try_send("InsertCoin"))
  ignore(engine.try_send("InsertCoin"))
  ignore(engine.try_send("CheckBalance"))

  println("State after payment: \{engine.state()}")
  println("Context after payment: \{engine.context()}")
  println("Mermaid Diagram:\n" + @fsm.to_mermaid(builder))
}
