///|
test "validate isolated states" {
  let builder : Builder[String, String, Unit] = Builder::new()
    .transition("Idle", "Start", "Running")
    .transition("Orphan", "Foo", "Bar")

  let isolated = validate(builder, "Idle")
  // Both Orphan and Bar are isolated from Idle
  inspect(isolated.length(), content="2")
}
