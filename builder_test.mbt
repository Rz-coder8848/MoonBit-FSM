///|
test "basic transitions" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition("Idle", "Start", "Running")
    .transition("Running", "Stop", "Stopped")

  let engine = builder.build("Idle", ())

  inspect(engine.state(), content="Idle")

  let res1 = engine.send("Start")
  inspect(res1 is Ok(_), content="true")
  inspect(engine.state(), content="Running")

  let res2 = engine.send("Stop")
  inspect(res2 is Ok(_), content="true")
  inspect(engine.state(), content="Stopped")
}

///|
test "invalid transition" {
  let builder : Builder[String, String, Unit] = Builder::new().transition(
    "Idle", "Start", "Running",
  )

  let engine = builder.build("Idle", ())

  let res = engine.send("Stop")
  inspect(res is Err(_), content="true")
  inspect(engine.state(), content="Idle")
}

///|
test "transition with guard" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition_if("Idle", "Start", "Running", fn(_s, _e, _ctx) { false })
    .transition_if("Idle", "ForceStart", "Running", fn(_s, _e, _ctx) { true })

  let engine = builder.build("Idle", ())

  let res1 = engine.send("Start")
  inspect(res1 is Err(_), content="true")
  inspect(engine.state(), content="Idle")

  let res2 = engine.send("ForceStart")
  inspect(res2 is Ok(_), content="true")
  inspect(engine.state(), content="Running")
}
