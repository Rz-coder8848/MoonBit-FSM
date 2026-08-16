///|
test "graph analysis identifies branches, terminals, cycles, and orphans" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition("Draft", "Submit", "Review")
    .transition("Draft", "Cancel", "Cancelled")
    .transition("Review", "Rework", "Draft")
    .transition("Review", "Approve", "Done")
    .transition("Orphan", "Ignore", "Unused")
  let summary = graph_summary(builder, "Draft")
  inspect(summary.state_count, content="6")
  inspect(summary.transition_count, content="5")
  inspect(summary.branching_states.length(), content="2")
  inspect(summary.terminal_states.length(), content="3")
  inspect(summary.unreachable_states.length(), content="2")
  inspect(summary.has_cycle, content="true")
  inspect(summary.maximum_exploration_depth, content="2")
}

///|
test "risk score penalizes duplicate and unreachable definitions" {
  let healthy : Builder[String, String, Unit] = Builder::new()
    .transition("A", "Go", "B")
    .transition("B", "Stop", "C")
  let risky : Builder[String, String, Unit] = Builder::new()
    .transition("A", "Go", "B")
    .transition("A", "Go", "Other")
    .transition("Orphan", "Lost", "Nowhere")
  inspect(
    workflow_risk_score(healthy, "A") > workflow_risk_score(risky, "A"),
    content="true",
  )
}
