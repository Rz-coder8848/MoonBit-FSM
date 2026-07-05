///|
test "engine send operations" {
  let builder : Builder[String, String, Unit] = Builder::new().transition(
    "Init", "Go", "Done",
  )

  let engine = builder.build("Init", ())
  inspect(engine.state(), content="Init")

  let res = engine.send("Go")
  inspect(res is Ok(_), content="true")
  inspect(engine.state(), content="Done")
}
