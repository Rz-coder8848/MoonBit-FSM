///|
test "guard failure returns structured error and keeps state" {
  let builder : Builder[String, String, Unit] = Builder::new().transition_if(
    "Idle",
    "Start",
    "Running",
    fn(_s, _e, _ctx) { false },
  )

  let engine = builder.build("Idle", ())
  let result = engine.try_send("Start")

  inspect(result is Err(GuardRejected), content="true")
  inspect(engine.last_error() is Some(GuardRejected), content="true")
  inspect(engine.state(), content="Idle")
}

///|
test "unknown event returns structured error" {
  let builder : Builder[String, String, Unit] = Builder::new().transition(
    "Idle", "Start", "Running",
  )

  let engine = builder.build("Idle", ())
  let result = engine.try_send("Stop")

  inspect(result is Err(EventNotHandledInCurrentState), content="true")
  inspect(engine.send("Stop") is Err(_), content="true")
  inspect(
    format_transition_error(EventNotHandledInCurrentState),
    content="Event not handled in current state",
  )
}

///|
test "history captures guard and action usage" {
  let builder : Builder[String, String, Int] = Builder::new().transition_if_do(
    "Review",
    "Approve",
    "Approved",
    fn(_s, _e, ctx) { ctx >= 2 },
    fn(_s, _e, ctx) { ctx + 10 },
  )

  let engine = builder.build("Review", 2)
  inspect(engine.try_send("Approve") is Ok(_), content="true")
  inspect(engine.context(), content="12")
  inspect(engine.history()[0].used_guard, content="true")
  inspect(engine.history()[0].used_action, content="true")
}
