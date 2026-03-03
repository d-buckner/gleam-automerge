# gleam_automerge

Gleam bindings for [automerge-rs](https://github.com/automerge/automerge) via a Rustler NIF.

Automerge is a CRDT library for building collaborative applications. This package exposes
the automerge sync protocol so multiple peers can converge on a shared document state.

## Installation

```sh
gleam add gleam_automerge
```

## Usage

```gleam
import gleam_automerge

// Create a new document
let doc = gleam_automerge.doc_new()

// Sync two documents
let state_a = gleam_automerge.sync_state_new()
let state_b = gleam_automerge.sync_state_new()

// Generate and exchange sync messages until both sides are in sync
let msg = gleam_automerge.generate_sync_message(doc, state_a)
// ... send msg to peer, receive their message ...
gleam_automerge.receive_sync_message(doc, state_b, msg)
```

## Building from source

Requires Rust. Set `AUTOMERGE_BUILD=1` to compile the NIF locally:

```sh
AUTOMERGE_BUILD=1 gleam test
```

## License

MIT
