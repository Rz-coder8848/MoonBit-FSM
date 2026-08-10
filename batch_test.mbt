///|
test "batch dispatch preserves order and reports mixed outcomes" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition("A", "go", "B")
    .transition("B", "finish", "C")
  let engine = builder.build("A", ())

  let report = engine.try_send_all(["go", "missing", "finish"])

  inspect(report.successful, content="2")
  inspect(report.rejected, content="1")
  inspect(report.complete, content="false")
  inspect(report.outcomes.length(), content="3")
  inspect(report.outcomes[0].event, content="go")
  inspect(
    report.outcomes[1].error is Some(EventNotHandledInCurrentState),
    content="true",
  )
  inspect(engine.state(), content="C")
}

///|
test "batch rejection can be compensated with a checkpoint" {
  let builder : Builder[String, String, Int] = Builder::new()
    .transition_do("Created", "Pay", "Paid", fn(_s, _e, ctx) { ctx + 1 })
    .transition("Paid", "Ship", "Shipped")
  let engine = builder.build("Created", 0)
  let checkpoint = engine.checkpoint()

  let report = engine.try_send_all(["Pay", "Unknown", "Ship"])
  inspect(report.complete, content="false")
  inspect(engine.state(), content="Shipped")

  engine.restore(checkpoint)
  inspect(engine.state(), content="Created")
  inspect(engine.context(), content="0")
  inspect(engine.history().length(), content="0")
}
