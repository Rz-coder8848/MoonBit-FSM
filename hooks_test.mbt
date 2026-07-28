///|
test "lifecycle hooks run after action in stable order" {
  let builder : Builder[String, String, Array[String]] = Builder::new()
    .transition_do("Idle", "Start", "Running", fn(
      _s : String,
      _e : String,
      ctx : Array[String],
    ) {
      ctx.push("action")
      ctx
    })
    .on_exit("Idle", fn(_s : String, _e : String, ctx : Array[String]) {
      ctx.push("exit:Idle")
    })
    .on_enter("Running", fn(_s : String, _e : String, ctx : Array[String]) {
      ctx.push("enter:Running")
    })

  let engine = builder.build("Idle", [])
  inspect(engine.try_send("Start") is Ok(_), content="true")
  inspect(engine.context().join("|"), content="action|exit:Idle|enter:Running")
  inspect(engine.history().length(), content="1")
}
