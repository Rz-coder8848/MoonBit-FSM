///|
test "validate report captures unreachable and dead end states" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition("Idle", "Start", "Running")
    .transition("Running", "Finish", "Done")
    .transition("Orphan", "Foo", "Bar")

  let report = validate_report(builder, "Idle")

  inspect(report.unreachable_states.length(), content="2")
  inspect(report.dead_end_states.length(), content="1")
  inspect(report.states_without_outgoing_edges.length(), content="2")
}

///|
test "validate report captures duplicate transitions" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition("Idle", "Start", "Running")
    .transition("Idle", "Start", "Broken")

  let report = validate_report(builder, "Idle")
  inspect(report.duplicate_transitions.length(), content="1")
}
