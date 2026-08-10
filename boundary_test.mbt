///|
test "empty builder reports missing transitions without changing state" {
  let builder : Builder[String, String, Unit] = Builder::new()
  let engine = builder.build("Idle", ())

  inspect(
    engine.try_send("Start") is Err(NoTransitionsForCurrentState),
    content="true",
  )
  inspect(engine.state(), content="Idle")
  inspect(engine.history().length(), content="0")
}

///|
test "dead end state rejects later events and does not add history" {
  let builder : Builder[String, String, Unit] = Builder::new().transition(
    "Idle", "Stop", "Stopped",
  )
  let engine = builder.build("Idle", ())

  ignore(engine.try_send("Stop"))
  inspect(
    engine.try_send("Reset") is Err(NoTransitionsForCurrentState),
    content="true",
  )
  inspect(engine.state(), content="Stopped")
  inspect(engine.history().length(), content="1")
}

///|
test "guard rejection preserves context hooks and history" {
  let builder : Builder[String, String, Int] = Builder::new().transition_if_do(
    "Idle",
    "Start",
    "Running",
    fn(_s, _e, _ctx) { false },
    fn(_s, _e, ctx) { ctx + 1 },
  )
  let engine = builder.build("Idle", 7)

  inspect(engine.try_send("Start") is Err(GuardRejected), content="true")
  inspect(engine.context(), content="7")
  inspect(engine.state(), content="Idle")
  inspect(engine.history().length(), content="0")
}

///|
test "duplicate definitions fail before a transition can have side effects" {
  let builder : Builder[String, String, Int] = Builder::new()
    .transition_do("Idle", "Start", "Running", fn(_s, _e, ctx) { ctx + 1 })
    .transition("Idle", "Start", "Broken")
  let engine = builder.build("Idle", 3)

  inspect(
    engine.try_send("Start") is Err(DuplicateTransitionDefinition),
    content="true",
  )
  inspect(engine.context(), content="3")
  inspect(engine.state(), content="Idle")
  inspect(engine.history().length(), content="0")
}

///|
test "history keeps transition order and failed events out" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition("A", "go", "B")
    .transition("B", "go", "C")
  let engine = builder.build("A", ())

  ignore(engine.try_send("go"))
  ignore(engine.try_send("missing"))
  ignore(engine.try_send("go"))
  inspect(engine.history()[0].from, content="A")
  inspect(engine.history()[0].to, content="B")
  inspect(engine.history()[1].from, content="B")
  inspect(engine.history()[1].to, content="C")
  inspect(engine.history().length(), content="2")
}

///|
test "empty Mermaid export remains a valid state diagram" {
  let builder : Builder[String, String, Unit] = Builder::new()
  inspect(to_mermaid(builder), content="stateDiagram-v2\n")
}
