import gleam/option.{type Option}
import gleam/result

/// An opaque reference to an Automerge document.
/// Created with `new_doc/0` or `load_doc/1`.
pub type DocRef

/// An opaque reference to the sync state for a single peer connection.
/// Each peer you sync with needs its own `SyncStateRef`.
pub type SyncStateRef

/// Errors returned by fallible operations.
pub type AutomergeError {
  /// The binary passed to `load_doc` is not a valid Automerge document.
  InvalidBinary(reason: String)
  /// The Rust NIF returned an unexpected error.
  NifError(reason: String)
}

// ── Doc lifecycle ─────────────────────────────────────────────────────────────

/// Create a new, empty Automerge document.
@external(erlang, "Elixir.AutomergeNif", "doc_new")
pub fn new_doc() -> DocRef

@external(erlang, "Elixir.AutomergeNif", "doc_load")
fn doc_load_nif(binary: BitArray) -> Result(DocRef, String)

/// Load a document from a binary produced by `save_doc` or `save_doc_incremental`.
pub fn load_doc(binary: BitArray) -> Result(DocRef, AutomergeError) {
  doc_load_nif(binary)
  |> result.map_error(InvalidBinary)
}

/// Serialise the full document state to a binary.
@external(erlang, "Elixir.AutomergeNif", "doc_save")
pub fn save_doc(doc: DocRef) -> BitArray

/// Serialise only the changes since the last `save_doc_incremental` call.
/// More efficient than `save_doc` for frequent checkpointing.
@external(erlang, "Elixir.AutomergeNif", "doc_save_incremental")
pub fn save_doc_incremental(doc: DocRef) -> BitArray

/// Return the current document state as a JSON string.
@external(erlang, "Elixir.AutomergeNif", "doc_get_json")
pub fn get_json(doc: DocRef) -> String

// ── Sync protocol ─────────────────────────────────────────────────────────────

/// Create a new sync state for a peer connection.
/// One `SyncStateRef` is required per peer you wish to sync with.
@external(erlang, "Elixir.AutomergeNif", "sync_state_new")
pub fn new_sync_state() -> SyncStateRef

/// Generate the next sync message to send to a peer.
/// Returns `None` when the two sides are fully in sync.
// The Rust NIF returns `{some, binary}` or `none`, which Gleam decodes as
// Option(BitArray). See generate_sync_message implementation in lib.rs.
@external(erlang, "Elixir.AutomergeNif", "generate_sync_message")
pub fn generate_sync_message(
  doc: DocRef,
  state: SyncStateRef,
) -> Option(BitArray)

@external(erlang, "Elixir.AutomergeNif", "receive_sync_message")
fn receive_sync_message_nif(
  doc: DocRef,
  state: SyncStateRef,
  msg: BitArray,
) -> Result(BitArray, String)

/// Apply a sync message received from a peer.
/// Returns the updated document binary, or an error if the message is invalid.
pub fn receive_sync_message(
  doc: DocRef,
  state: SyncStateRef,
  msg: BitArray,
) -> Result(BitArray, AutomergeError) {
  receive_sync_message_nif(doc, state, msg)
  |> result.map_error(NifError)
}
