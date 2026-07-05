///|
fn main {
  println("--- Game NPC AI Example ---")

  let builder : @fsm.Builder[String, String, Unit] = @fsm.Builder::new()
    .transition("Patrol", "PlayerSpotted", "Chase")
    .transition("Chase", "PlayerLost", "Search")
    .transition("Search", "Timeout", "Patrol")
    .transition("Chase", "InAttackRange", "Attack")
    .transition("Attack", "PlayerOutOfRange", "Chase")
    .transition("Attack", "PlayerDefeated", "Patrol")

  println("Mermaid Diagram:\n" + @fsm.to_mermaid(builder))
}
