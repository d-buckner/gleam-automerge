import gleam/option.{type Option}
import gleam/result

pub type DocRef

pub type SyncStateRef

pub type AutomergeError {
  InvalidBinary(reason: String)
  NifError(reason: String)
}

// ── Doc lifecycle ─────────────────────────────────────────────────────────────

@external(erlang, "Elixir.AutomergeNif", "doc_new")
pub fn new_doc() -> DocRef

@external(erlang, "Elixir.AutomergeNif", "doc_load")
fn doc_load_nif(binary: BitArray) -> Result(DocRef, String)

pub fn load_doc(binary: BitArray) -> Result(DocRef, AutomergeError) {
  doc_load_nif(binary)
  |> result.map_error(InvalidBinary)
}

@external(erlang, "Elixir.AutomergeNif", "doc_save")
pub fn save_doc(doc: DocRef) -> BitArray

@external(erlang, "Elixir.AutomergeNif", "doc_save_incremental")
pub fn save_doc_incremental(doc: DocRef) -> BitArray

@external(erlang, "Elixir.AutomergeNif", "doc_get_json")
pub fn get_json(doc: DocRef) -> String

// ── Sync protocol ─────────────────────────────────────────────────────────────

@external(erlang, "Elixir.AutomergeNif", "sync_state_new")
pub fn new_sync_state() -> SyncStateRef

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

pub fn receive_sync_message(
  doc: DocRef,
  state: SyncStateRef,
  msg: BitArray,
) -> Result(BitArray, AutomergeError) {
  receive_sync_message_nif(doc, state, msg)
  |> result.map_error(NifError)
}
