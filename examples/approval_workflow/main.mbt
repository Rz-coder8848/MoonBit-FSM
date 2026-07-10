///|
struct WorkflowContext {
  score : Int
  attempts : Int
}

///|
fn main {
  println("--- Approval Workflow Example ---")

  let builder : @fsm.Builder[String, String, WorkflowContext] = @fsm.Builder::new()
    .transition_do("Draft", "Submit", "Review.Pending", fn(
      _s : String,
      _e : String,
      ctx : WorkflowContext,
    ) {
      { score: ctx.score, attempts: ctx.attempts + 1 }
    })
    .transition_if_do(
      "Review.Pending",
      "Approve",
      "Review.Approved",
      fn(_s : String, _e : String, ctx : WorkflowContext) { ctx.score >= 80 },
      fn(_s : String, _e : String, ctx : WorkflowContext) {
        { score: ctx.score + 5, attempts: ctx.attempts }
      },
    )
    .transition("Review.Pending", "RequestChanges", "Review.Rework")
    .transition("Review.Pending", "Cancel", "Cancelled")
    .transition("Review.Pending", "Reject", "Review.Rejected")
    .transition_do("Review.Rework", "Resubmit", "Review.Pending", fn(
      _s : String,
      _e : String,
      ctx : WorkflowContext,
    ) {
      { score: ctx.score + 20, attempts: ctx.attempts }
    })
    .transition("Review.Rework", "Cancel", "Cancelled")
    .transition("Review.Rejected", "Escalate", "Error.Validation")
    .transition("Review.Approved", "Archive", "Closed")

  let engine = builder.build("Draft", { score: 70, attempts: 0 })
  ignore(engine.try_send("Submit"))
  ignore(engine.try_send("RequestChanges"))
  ignore(engine.try_send("Resubmit"))
  ignore(engine.try_send("Approve"))
  ignore(engine.try_send("Archive"))

  println("Final state: \{engine.state()}")
  println("Final score: \{engine.context().score}")
  println("History length: \{engine.history().length()}")
  println("Mermaid Diagram:\n" + @fsm.to_mermaid(builder))
}
