///|
fn main {
  println("--- Vending Machine Example ---")

  let builder : @fsm.Builder[String, String, Int] = @fsm.Builder::new()
    .transition_do("Idle", "InsertCoin", "Counting", fn(_s, _e, ctx) { ctx + 5 })
    .transition_do("Counting", "InsertCoin", "Counting", fn(_s, _e, ctx) {
      ctx + 5
    })
    .transition_if("Counting", "SelectItem", "Unlocked", fn(_s, _e, ctx) {
      ctx >= 10
    })
    .transition_do("Unlocked", "Dispense", "Idle", fn(_s, _e, _ctx) { 0 })
    .on_enter("Unlocked", fn(_s, _e, ctx) {
      println("Ready to dispense, current balance: \{ctx}")
    })

  let engine = builder.build("Idle", 0)
  ignore(engine.try_send("InsertCoin"))
  match engine.try_send("SelectItem") {
    Ok(_) => println("Unexpected unlock without enough balance")
    Err(err) =>
      println("First selection blocked: \{@fsm.format_transition_error(err)}")
  }
  ignore(engine.try_send("InsertCoin"))
  ignore(engine.try_send("SelectItem"))

  println("State after payment: \{engine.state()}")
  println("Context after payment: \{engine.context()}")
  println("Transition count: \{engine.history().length()}")
  println("Mermaid Diagram:\n" + @fsm.to_mermaid(builder))
}
