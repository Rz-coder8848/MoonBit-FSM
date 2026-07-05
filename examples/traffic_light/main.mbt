///|
fn main {
  println("--- Traffic Light Example ---")

  let builder : @fsm.Builder[String, String, Unit] = @fsm.Builder::new()
    .transition("Red", "Timer", "Green")
    .transition("Green", "Timer", "Yellow")
    .transition("Yellow", "Timer", "Red")
    .transition("Red", "PowerOutage", "Off")
    .transition("Green", "PowerOutage", "Off")
    .transition("Yellow", "PowerOutage", "Off")
    .transition("Off", "PowerRestore", "Red")

  let isolated = @fsm.validate(builder, "Red")
  println("Unreachable states: \{isolated.length()}")

  println("Mermaid Diagram:\n" + @fsm.to_mermaid(builder))
}
