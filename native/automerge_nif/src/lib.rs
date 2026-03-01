use automerge::sync;
use automerge::AutoCommit;
use rustler::{Binary, Env, NifResult, OwnedBinary, ResourceArc, Term};
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

#[rustler::nif]
fn doc_new() -> ResourceArc<DocResource> {
    unimplemented!()
}

#[rustler::nif(schedule = "DirtyCpu")]
fn doc_load(binary: Binary) -> NifResult<ResourceArc<DocResource>> {
    let _ = binary;
    unimplemented!()
}

#[rustler::nif(schedule = "DirtyCpu")]
fn doc_save<'a>(env: Env<'a>, doc: ResourceArc<DocResource>) -> Binary<'a> {
    let _ = (env, doc);
    unimplemented!()
}

#[rustler::nif]
fn doc_save_incremental<'a>(env: Env<'a>, doc: ResourceArc<DocResource>) -> Binary<'a> {
    let _ = (env, doc);
    unimplemented!()
}

#[rustler::nif]
fn doc_get_json(doc: ResourceArc<DocResource>) -> String {
    let _ = doc;
    unimplemented!()
}

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
