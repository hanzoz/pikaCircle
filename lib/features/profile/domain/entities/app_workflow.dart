/// The top-level app shell a user sees, derived from their roles.
///
/// Doc rule: the workflow is [host] when the user's roles contain `host`,
/// otherwise [player]. (An `admin`-only user still sees the player shell in the
/// current app; the host tab requires the explicit `host` role.)
/// Domain-only: no Flutter or Appwrite imports.
enum AppWorkflow {
  player,
  host,
}
