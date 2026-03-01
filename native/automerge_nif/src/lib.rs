use automerge::sync::{self, SyncDoc};
use automerge::{AutoCommit, AutoSerde};
use rustler::{Binary, Encoder, Env, OwnedBinary, ResourceArc, Term};
use std::sync::Mutex;

pub struct DocResource(pub Mutex<AutoCommit>);
pub struct SyncStateResource(pub Mutex<sync::State>);

#[rustler::resource_impl]
impl rustler::Resource for DocResource {}

#[rustler::resource_impl]
impl rustler::Resource for SyncStateResource {}

rustler::atoms! {
    ok,
    error,
    some,
    none,
}

rustler::init!("Elixir.AutomergeNif");

// ── Doc lifecycle ──────────────────────────────────────────────────────────────

#[rustler::nif]
fn doc_new() -> ResourceArc<DocResource> {
    ResourceArc::new(DocResource(Mutex::new(AutoCommit::new())))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn doc_load<'a>(env: Env<'a>, binary: Binary) -> Term<'a> {
    match AutoCommit::load(binary.as_slice()) {
        Ok(doc) => {
            let arc = ResourceArc::new(DocResource(Mutex::new(doc)));
            (ok(), arc).encode(env)
        }
        Err(e) => (error(), e.to_string()).encode(env),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn doc_save<'a>(env: Env<'a>, doc: ResourceArc<DocResource>) -> Binary<'a> {
    let mut doc = doc.0.lock().unwrap();
    let bytes = doc.save();
    let mut owned = OwnedBinary::new(bytes.len()).unwrap();
    owned.as_mut_slice().copy_from_slice(&bytes);
    Binary::from_owned(owned, env)
}

#[rustler::nif]
fn doc_save_incremental<'a>(env: Env<'a>, doc: ResourceArc<DocResource>) -> Binary<'a> {
    let mut doc = doc.0.lock().unwrap();
    let bytes = doc.save_incremental();
    let mut owned = OwnedBinary::new(bytes.len()).unwrap();
    owned.as_mut_slice().copy_from_slice(&bytes);
    Binary::from_owned(owned, env)
}

#[rustler::nif]
fn doc_get_json(doc: ResourceArc<DocResource>) -> String {
    let doc = doc.0.lock().unwrap();
    serde_json::to_string(&AutoSerde::from(&*doc)).unwrap_or_else(|_| "{}".to_string())
}

// ── Sync protocol ──────────────────────────────────────────────────────────────

#[rustler::nif]
fn sync_state_new() -> ResourceArc<SyncStateResource> {
    ResourceArc::new(SyncStateResource(Mutex::new(sync::State::new())))
}

// Returns `{some, binary}` or `none` — Gleam's Option(BitArray) encoding.
#[rustler::nif]
fn generate_sync_message<'a>(
    env: Env<'a>,
    doc: ResourceArc<DocResource>,
    state: ResourceArc<SyncStateResource>,
) -> Term<'a> {
    let mut doc = doc.0.lock().unwrap();
    let mut state = state.0.lock().unwrap();
    // Scope the SyncWrapper so its mutable borrow of doc ends before we encode.
    let maybe_msg: Option<sync::Message> = { doc.sync().generate_sync_message(&mut *state) };
    match maybe_msg {
        Some(msg) => {
            let bytes: Vec<u8> = msg.encode();
            let mut owned = OwnedBinary::new(bytes.len()).unwrap();
            owned.as_mut_slice().copy_from_slice(&bytes);
            let bin = Binary::from_owned(owned, env);
            (some(), bin).encode(env)
        }
        None => none().encode(env),
    }
}

// Returns `{ok, <<>>}` or `{error, String}` — Gleam's Result(BitArray, String) encoding.
#[rustler::nif(schedule = "DirtyCpu")]
fn receive_sync_message<'a>(
    env: Env<'a>,
    doc: ResourceArc<DocResource>,
    state: ResourceArc<SyncStateResource>,
    msg: Binary<'a>,
) -> Term<'a> {
    let mut doc = doc.0.lock().unwrap();
    let mut state = state.0.lock().unwrap();
    let message = match sync::Message::decode(msg.as_slice()) {
        Ok(m) => m,
        Err(e) => return (error(), e.to_string()).encode(env),
    };
    // Scope the SyncWrapper so its mutable borrow of doc ends before we encode.
    let result: Result<(), _> = { doc.sync().receive_sync_message(&mut *state, message) };
    match result {
        Ok(_) => {
            let owned = OwnedBinary::new(0).unwrap();
            (ok(), Binary::from_owned(owned, env)).encode(env)
        }
        Err(e) => (error(), e.to_string()).encode(env),
    }
}
