# gleam-automerge — Design Document
*2026-03-01*

## Overview

A standalone Gleam package providing idiomatic bindings to automerge-rs via a Rustler NIF. Targets publication on hex.pm. Scope is v1: doc lifecycle + sync protocol (~10 NIF functions).

---

## Repo Structure

```
automerge/
  native/automerge_nif/        # Rust crate (Rustler NIF)
    src/lib.rs
    Cargo.toml
  src/
    automerge.gleam            # Public Gleam API
  lib/
    automerge_nif.ex           # Thin Elixir shim (loads NIF via Rustler)
  test/
    automerge_test.gleam       # Integration tests
  .github/workflows/
    ci.yml                     # PR: compile + test
    release.yml                # Tag: cross-compile matrix
  mix.exs
  gleam.toml
```

---

## Rust NIF Layer

Two opaque resource types registered with the BEAM:

```rust
struct DocResource(Mutex<AutoCommit>);
struct SyncStateResource(Mutex<sync::State>);
```

Returned to Gleam as `ResourceArc<T>` handles; lifetime managed by the BEAM GC.

### Exposed functions

```rust
// Doc lifecycle
doc_new() -> ResourceArc<DocResource>
doc_load(binary: Binary) -> NifResult<ResourceArc<DocResource>>          // DirtyCpu
doc_save(doc: ResourceArc<DocResource>) -> Binary                        // DirtyCpu
doc_save_incremental(doc: ResourceArc<DocResource>) -> Binary
doc_get_json(doc: ResourceArc<DocResource>) -> Binary

// Sync protocol
sync_state_new() -> ResourceArc<SyncStateResource>
generate_sync_message(doc, state) -> Option<Binary>
receive_sync_message(doc, state, msg: Binary) -> NifResult<Binary>       // DirtyCpu
```

`DirtyCpu` is applied to serialisation-heavy operations to avoid blocking BEAM schedulers.

---

## Elixir Shim

`lib/automerge_nif.ex` — thin NIF loader, invisible to consumers:

```elixir
defmodule AutomergeNif do
  use Rustler, otp_app: :automerge, crate: :automerge_nif

  def doc_new(), do: :erlang.nif_error(:nif_not_loaded)
  def doc_load(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def doc_save(_doc), do: :erlang.nif_error(:nif_not_loaded)
  def doc_save_incremental(_doc), do: :erlang.nif_error(:nif_not_loaded)
  def doc_get_json(_doc), do: :erlang.nif_error(:nif_not_loaded)
  def sync_state_new(), do: :erlang.nif_error(:nif_not_loaded)
  def generate_sync_message(_doc, _state), do: :erlang.nif_error(:nif_not_loaded)
  def receive_sync_message(_doc, _state, _msg), do: :erlang.nif_error(:nif_not_loaded)
end
```

---

## Gleam Public API

Single module `src/automerge.gleam`. Translates NIF return tuples into Gleam `Result` and `Option` types. No business logic.

```gleam
pub type DocRef        // opaque ResourceArc handle
pub type SyncStateRef  // opaque ResourceArc handle

pub type AutomergeError {
  InvalidBinary(reason: String)
  NifError(reason: String)
}

// Doc lifecycle
pub fn new_doc() -> DocRef
pub fn load_doc(binary: BitArray) -> Result(DocRef, AutomergeError)
pub fn save_doc(doc: DocRef) -> BitArray
pub fn save_doc_incremental(doc: DocRef) -> BitArray
pub fn get_json(doc: DocRef) -> String

// Sync protocol
pub fn new_sync_state() -> SyncStateRef
pub fn generate_sync_message(doc: DocRef, state: SyncStateRef) -> Option(BitArray)
pub fn receive_sync_message(
  doc: DocRef,
  state: SyncStateRef,
  msg: BitArray,
) -> Result(BitArray, AutomergeError)
```

---

## Testing

Integration tests in `test/automerge_test.gleam`. Rust must be available at test time (tests load the compiled NIF).

### Coverage

**Doc lifecycle**
- `new_doc()` returns a valid `DocRef`
- Save/load round-trip: `save_doc |> load_doc` produces an equivalent doc
- `save_doc_incremental` returns a non-empty binary
- `get_json` returns valid JSON for an empty doc
- `load_doc` with invalid binary returns `Error(InvalidBinary(...))`

**Sync protocol**
- `new_sync_state()` returns a valid `SyncStateRef`
- Two-doc sync: doc A and doc B exchange messages until `generate_sync_message` returns `None` (sync complete)
- `receive_sync_message` with a corrupt message returns `Error(...)`

---

## CI / Distribution

### `ci.yml` (PRs)
- Compile Rust NIF locally
- Run Gleam integration test suite

### `release.yml` (version tags `v*`)
Cross-compile matrix using the `cross` tool:

| Target | Platform |
|---|---|
| `x86_64-unknown-linux-gnu` | Linux x86 |
| `aarch64-unknown-linux-gnu` | Linux ARM |
| `x86_64-apple-darwin` | macOS Intel |
| `aarch64-apple-darwin` | macOS Apple Silicon |

Compiled `.so`/`.dylib` artifacts and SHA256 checksums are uploaded to the GitHub release. `mix.exs` configures RustlerPrecompiled to download the correct binary at `mix deps.compile` — consumers do not need Rust installed.

Dev workflow uses the local Rust toolchain directly; precompiled binaries are for downstream consumers only.

---

## Open Questions (deferred to v2)

- Broader automerge-rs surface: map/list/text mutations, actor IDs, change inspection
- Module split (`automerge/doc`, `automerge/sync`) if API surface grows
- Persistence abstractions
