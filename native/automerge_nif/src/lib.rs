use automerge::sync;
use automerge::{AutoCommit, AutoSerde};
use rustler::{Binary, Encoder, Env, NifResult, OwnedBinary, ResourceArc, Term};
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
    unimplemented!()
}

#[rustler::nif]
fn generate_sync_message<'a>(
    env: Env<'a>,
    doc: ResourceArc<DocResource>,
    state: ResourceArc<SyncStateResource>,
) -> Term<'a> {
    let _ = (env, doc, state);
    unimplemented!()
}

#[rustler::nif(schedule = "DirtyCpu")]
fn receive_sync_message<'a>(
    env: Env<'a>,
    doc: ResourceArc<DocResource>,
    state: ResourceArc<SyncStateResource>,
    msg: Binary<'a>,
) -> NifResult<Binary<'a>> {
    let _ = (env, doc, state, msg);
    unimplemented!()
}
