///|
struct ReviewContext {
  score : Int
  attempts : Int
} derive(Eq)

///|
fn approval_builder() -> Builder[String, String, ReviewContext] {
  Builder::new()
  .transition_do("Draft", "Submit", "Review.Pending", fn(
    _s : String,
    _e : String,
    ctx : ReviewContext,
  ) {
    { score: ctx.score, attempts: ctx.attempts + 1 }
  })
  .transition_if_do(
    "Review.Pending",
    "Approve",
    "Review.Approved",
    fn(_s : String, _e : String, ctx : ReviewContext) { ctx.score >= 80 },
    fn(_s : String, _e : String, ctx : ReviewContext) {
      { score: ctx.score + 5, attempts: ctx.attempts }
    },
  )
  .transition("Review.Pending", "RequestChanges", "Review.Rework")
  .transition("Review.Pending", "Cancel", "Cancelled")
  .transition("Review.Pending", "Reject", "Review.Rejected")
  .transition_do("Review.Rework", "Resubmit", "Review.Pending", fn(
    _s : String,
    _e : String,
    ctx : ReviewContext,
  ) {
    { score: ctx.score + 20, attempts: ctx.attempts }
  })
  .transition("Review.Rejected", "Escalate", "Error.Validation")
  .transition("Review.Rework", "Cancel", "Cancelled")
  .transition("Review.Approved", "Archive", "Closed")
}

///|
test "workflow example covers happy path and history" {
  let engine = approval_builder().build("Draft", { score: 70, attempts: 0 })

  ignore(engine.try_send("Submit"))
  ignore(engine.try_send("RequestChanges"))
  ignore(engine.try_send("Resubmit"))
  ignore(engine.try_send("Approve"))
  ignore(engine.try_send("Archive"))

  inspect(engine.state(), content="Closed")
  inspect(engine.context().score, content="95")
  inspect(engine.context().attempts, content="1")
  inspect(engine.history().length(), content="5")
}

///|
test "workflow example covers guard failure and error branch" {
  let engine = approval_builder().build("Draft", { score: 60, attempts: 0 })

  ignore(engine.try_send("Submit"))
  inspect(engine.try_send("Approve") is Err(GuardRejected), content="true")
  inspect(engine.state(), content="Review.Pending")
  inspect(engine.try_send("Reject") is Ok(_), content="true")
  inspect(engine.state(), content="Review.Rejected")
  inspect(engine.try_send("Escalate") is Ok(_), content="true")
  inspect(engine.state(), content="Error.Validation")
}
