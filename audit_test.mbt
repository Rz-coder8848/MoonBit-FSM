///|
test "audit records successful and rejected attempts" {
  let builder : Builder[String, String, Int] = Builder::new().transition_do(
    "Idle",
    "Start",
    "Running",
    fn(_s, _e, ctx) { ctx + 1 },
  )
  let engine = builder.build("Idle", 0)

  ignore(engine.try_send("Start"))
  ignore(engine.try_send("Missing"))
  inspect(engine.metrics().attempted, content="2")
  inspect(engine.metrics().successful, content="1")
  inspect(engine.metrics().rejected, content="1")
  inspect(engine.audit_log().length(), content="2")
  inspect(engine.audit_log()[0].success, content="true")
  inspect(
    engine.audit_log()[1].error is Some(NoTransitionsForCurrentState),
    content="true",
  )
}

///|
test "metrics classify guard, unknown event, terminal, and duplicate failures" {
  let guarded : Builder[String, String, Unit] = Builder::new().transition_if(
    "Idle",
    "Start",
    "Running",
    fn(_s, _e, _ctx) { false },
  )
  let guarded_engine = guarded.build("Idle", ())
  ignore(guarded_engine.try_send("Start"))
  inspect(guarded_engine.metrics().guard_rejected, content="1")

  let unknown : Builder[String, String, Unit] = Builder::new().transition(
    "Idle", "Start", "Running",
  )
  let unknown_engine = unknown.build("Idle", ())
  ignore(unknown_engine.try_send("Stop"))
  inspect(unknown_engine.metrics().unknown_event, content="1")

  ignore(unknown_engine.try_send("Start"))
  ignore(unknown_engine.try_send("Stop"))
  inspect(unknown_engine.metrics().no_outgoing_state, content="1")

  let duplicate : Builder[String, String, Unit] = Builder::new()
    .transition("Idle", "Start", "Running")
    .transition("Idle", "Start", "Broken")
  let duplicate_engine = duplicate.build("Idle", ())
  ignore(duplicate_engine.try_send("Start"))
  inspect(duplicate_engine.metrics().duplicate_configuration, content="1")
}

///|
test "lifecycle callbacks are counted and metrics reset preserves history" {
  let builder : Builder[String, String, Array[String]] = Builder::new()
    .transition("Idle", "Start", "Running")
    .on_exit("Idle", fn(_s : String, _e : String, ctx : Array[String]) {
      ctx.push("exit")
    })
    .on_enter("Running", fn(_s : String, _e : String, ctx : Array[String]) {
      ctx.push("enter")
    })
  let engine = builder.build("Idle", [])

  ignore(engine.try_send("Start"))
  inspect(engine.metrics().lifecycle_hooks, content="2")
  inspect(engine.history().length(), content="1")
  engine.reset_metrics()
  inspect(engine.state(), content="Running")
  inspect(engine.history().length(), content="1")
  inspect(engine.metrics().attempted, content="0")
  inspect(engine.audit_log().length(), content="0")
}

///|
test "audit log reads are isolated from engine storage" {
  let builder : Builder[String, String, Unit] = Builder::new().transition(
    "Idle", "Start", "Running",
  )
  let engine = builder.build("Idle", ())
  ignore(engine.try_send("Start"))

  let entries = engine.audit_log()
  entries.clear()
  inspect(engine.audit_log().length(), content="1")
}

///|
test "history reads are isolated from engine storage" {
  let builder : Builder[String, String, Unit] = Builder::new().transition(
    "Idle", "Start", "Running",
  )
  let engine = builder.build("Idle", ())
  ignore(engine.try_send("Start"))

  let entries = engine.history()
  entries.clear()
  inspect(engine.history().length(), content="1")
}
