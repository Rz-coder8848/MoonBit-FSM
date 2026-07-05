///|
test "context manager operations" {
  let ctx_mgr = ContextManager::new(100)
  inspect(ctx_mgr.get(), content="100")

  ctx_mgr.set(200)
  inspect(ctx_mgr.get(), content="200")
}
