///|
test "checkpoint restores observable runtime state" {
  let builder : Builder[String, String, Int] = Builder::new().transition_do(
    "Idle",
    "Start",
    "Running",
    fn(_s, _e, ctx) { ctx + 1 },
  )
  let engine = builder.build("Idle", 0)
  let checkpoint = engine.checkpoint()

  ignore(engine.try_send("Start"))
  engine.restore(checkpoint)

  inspect(engine.state(), content="Idle")
  inspect(engine.context(), content="0")
  inspect(engine.history().length(), content="0")
  inspect(engine.audit_log().length(), content="0")
  inspect(engine.metrics().attempted, content="0")
}
