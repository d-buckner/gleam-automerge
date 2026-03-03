import gleam_automerge as automerge
import gleam/bit_array
import gleam/option
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

pub fn save_doc_returns_non_empty_binary_test() {
  let doc = automerge.new_doc()
  let bytes = automerge.save_doc(doc)
  should.be_true(bit_array.byte_size(bytes) > 0)
}

pub fn save_incremental_does_not_crash_test() {
  let doc = automerge.new_doc()
  let _bytes = automerge.save_doc_incremental(doc)
  should.be_ok(Ok(Nil))
}

pub fn get_json_returns_empty_object_for_new_doc_test() {
  let doc = automerge.new_doc()
  let json = automerge.get_json(doc)
  should.equal(json, "{}")
}

// ── Sync protocol ─────────────────────────────────────────────────────────────

pub fn new_sync_state_does_not_crash_test() {
  let _state = automerge.new_sync_state()
  should.be_ok(Ok(Nil))
}

pub fn two_doc_sync_completes_test() {
  let doc_a = automerge.new_doc()
  let doc_b = automerge.new_doc()
  let state_a = automerge.new_sync_state()
  let state_b = automerge.new_sync_state()
  sync_until_done(doc_a, state_a, doc_b, state_b, 0)
}

fn sync_until_done(doc_a, state_a, doc_b, state_b, rounds) {
  should.be_true(rounds < 10)
  let msg_a = automerge.generate_sync_message(doc_a, state_a)
  let msg_b = automerge.generate_sync_message(doc_b, state_b)
  case msg_a, msg_b {
    option.None, option.None -> Nil
    option.Some(msg), _ -> {
      automerge.receive_sync_message(doc_b, state_b, msg)
      |> should.be_ok
      sync_until_done(doc_a, state_a, doc_b, state_b, rounds + 1)
    }
    _, option.Some(msg) -> {
      automerge.receive_sync_message(doc_a, state_a, msg)
      |> should.be_ok
      sync_until_done(doc_a, state_a, doc_b, state_b, rounds + 1)
    }
  }
}

pub fn receive_invalid_sync_message_returns_error_test() {
  let doc = automerge.new_doc()
  let state = automerge.new_sync_state()
  automerge.receive_sync_message(doc, state, <<99, 98, 97>>)
  |> should.be_error
}
