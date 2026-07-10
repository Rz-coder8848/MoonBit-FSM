///|
test "basic transitions and history" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition("Idle", "Start", "Running")
    .transition("Running", "Stop", "Stopped")

  let engine = builder.build("Idle", ())

  inspect(engine.state(), content="Idle")
  inspect(engine.try_send("Start") is Ok(_), content="true")
  inspect(engine.state(), content="Running")
  inspect(engine.try_send("Stop") is Ok(_), content="true")
  inspect(engine.state(), content="Stopped")
  inspect(engine.history().length(), content="2")
}

///|
test "transition action updates context" {
  let builder : Builder[String, String, Int] = Builder::new().transition_do(
    "Draft",
    "Submit",
    "Review",
    fn(_s, _e, ctx) { ctx + 1 },
  )

  let engine = builder.build("Draft", 0)
  inspect(engine.try_send("Submit") is Ok(_), content="true")
  inspect(engine.context(), content="1")
  inspect(engine.history()[0].used_action, content="true")
}

///|
test "duplicate transitions are rejected by runtime" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition("Idle", "Start", "Running")
    .transition("Idle", "Start", "Broken")

  let duplicates = duplicate_transition_entries(builder)
  inspect(duplicates.length(), content="1")

  let engine = builder.build("Idle", ())
  let result = engine.try_send("Start")
  inspect(result is Err(DuplicateTransitionDefinition), content="true")
  inspect(
    engine.last_error() is Some(DuplicateTransitionDefinition),
    content="true",
  )
}
