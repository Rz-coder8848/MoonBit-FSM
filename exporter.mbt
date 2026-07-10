///|
/// Exports the FSM configuration as a Mermaid stateDiagram string.
pub fn[S : Show, E : Show, Ctx] to_mermaid(
  builder : Builder[S, E, Ctx],
) -> String {
  let mut diagram = "stateDiagram-v2\n"

  for t in builder.config.transitions {
    let from_str = "\{t.from}"
    let to_str = "\{t.to}"
    let event_str = "\{t.event}"
    let guard_suffix = match t.guard_cond {
      Some(_) => " [guard]"
      None => ""
    }
    let action_suffix = match t.action {
      Some(_) => " [action]"
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
      action_suffix +
      "\n"
  }

  diagram
}
