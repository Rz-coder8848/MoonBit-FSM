///|
test "mermaid export annotates guards and actions" {
  let builder : Builder[String, String, Int] = Builder::new()
    .transition_do("Idle", "InsertCoin", "Counting", fn(_s, _e, ctx) { ctx + 5 })
    .transition_if("Counting", "SelectItem", "Unlocked", fn(_s, _e, ctx) {
      ctx >= 10
    })
    .transition_do("Unlocked", "Dispense", "Idle", fn(_s, _e, _ctx) { 0 })

  inspect(
    to_mermaid(builder),
    content=(
      #|stateDiagram-v2
      #|    Idle --> Counting : InsertCoin [action]
      #|    Counting --> Unlocked : SelectItem [guard]
      #|    Unlocked --> Idle : Dispense [action]
      #|
    ),
  )
}
