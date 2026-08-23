/// Where a row stands relative to the (future) cloud.
///
/// Stored as the **enum index**, so these values must never be reordered and
/// new ones may only be appended. Unused in Phase 1 but present from the first
/// schema, because adding it later would mean migrating live user data
/// (D-011).
///
/// Lives in `data/models/` rather than beside the table that stores it: the
/// domain layer must not import drift (§3), so every enum a domain model
/// carries has to be declared somewhere drift-free. The table imports this,
/// never the other way round.
enum SyncStatus {
  /// Created on this device and never sent anywhere.
  local,

  /// Changed locally, awaiting upload.
  pending,

  /// Matches the server as of the row's `lastSyncedAt`.
  synced,

  /// Diverged from the server; needs resolution.
  conflict,
}
