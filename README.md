# gleam_automerge

Gleam bindings for [automerge-rs](https://github.com/automerge/automerge) via a Rustler NIF.

Automerge is a CRDT library for building collaborative applications. This package exposes
the automerge sync protocol so multiple peers can converge on a shared document state.

## Installation

### Gleam

```sh
gleam add gleam_automerge
```

### Mix / Elixir

```elixir
def deps do
  [
    {:gleam_automerge, "~> 0.2"}
  ]
end
```

## Usage

### Gleam

```gleam
import gleam_automerge

// Create a new document
let doc = gleam_automerge.new_doc()

// Sync two documents
let state_a = gleam_automerge.new_sync_state()
let state_b = gleam_automerge.new_sync_state()

// Exchange sync messages until both sides are in sync
case gleam_automerge.generate_sync_message(doc, state_a) {
  Some(msg) -> gleam_automerge.receive_sync_message(doc, state_b, msg)
  None -> Ok(Nil)
}
```

### Elixir

The public API is exposed via the `:gleam_automerge` Erlang module:

```elixir
doc = :gleam_automerge.new_doc()

state_a = :gleam_automerge.new_sync_state()
state_b = :gleam_automerge.new_sync_state()

case :gleam_automerge.generate_sync_message(doc, state_a) do
  {:some, msg} -> :gleam_automerge.receive_sync_message(doc, state_b, msg)
  :none -> :ok
end
```

## Building from source

Requires Rust. Set `AUTOMERGE_BUILD=1` to compile the NIF locally instead of
downloading a precompiled binary:

```sh
AUTOMERGE_BUILD=1 mix compile
```

## License

MIT
