import automerge
import gleam/bit_array
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ── Doc lifecycle ─────────────────────────────────────────────────────────────

pub fn new_doc_does_not_crash_test() {
  let _doc = automerge.new_doc()
  should.be_ok(Ok(Nil))
}

pub fn save_and_load_round_trip_test() {
  let original = automerge.new_doc()
  let saved = automerge.save_doc(original)
  automerge.load_doc(saved)
  |> should.be_ok
}

pub fn load_invalid_binary_returns_error_test() {
  let result = automerge.load_doc(<<1, 2, 3>>)
  case result {
    Error(automerge.InvalidBinary(_)) -> Nil
    _ -> panic as "expected InvalidBinary error"
  }
}

pub fn save_incremental_returns_non_empty_binary_test() {
  let doc = automerge.new_doc()
  let bytes = automerge.save_doc_incremental(doc)
  should.be_true(bit_array.byte_size(bytes) > 0)
}

pub fn get_json_returns_empty_object_for_new_doc_test() {
  let doc = automerge.new_doc()
  let json = automerge.get_json(doc)
  should.equal(json, "{}")
}
