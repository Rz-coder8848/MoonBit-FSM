///|
/// Exports the FSM configuration as a Mermaid stateDiagram string.
/// This allows developers to easily visualize their state machines.
pub fn[S : Show, E : Show, Ctx] to_mermaid(
  builder : Builder[S, E, Ctx],
) -> String {
  let mut diagram = "stateDiagram-v2\n"

  for t in builder.config.transitions {
    let from_str = "\{t.from}"
    let to_str = "\{t.to}"
    let event_str = "\{t.event}"

    // In Mermaid, states shouldn't have quotes, so we do basic cleanup if needed.
    // For simplicity, we just use the raw string representations.
    let guard_suffix = match t.guard_cond {
      Some(_) => " [Guard]"
      None => ""
    }

    diagram = diagram +
      "    " +
      from_str +
      " --> " +
      to_str +
      " : " +
      event_str +
      guard_suffix +
      "\n"
  }

  diagram
}
