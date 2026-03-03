-module(gleam_automerge).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gleam_automerge.gleam").
-export([new_doc/0, load_doc/1, save_doc/1, save_doc_incremental/1, get_json/1, new_sync_state/0, generate_sync_message/2, receive_sync_message/3]).
-export_type([doc_ref/0, sync_state_ref/0, automerge_error/0]).

-type doc_ref() :: any().

-type sync_state_ref() :: any().

-type automerge_error() :: {invalid_binary, binary()} | {nif_error, binary()}.

-file("src/gleam_automerge.gleam", 16).
-spec new_doc() -> doc_ref().
new_doc() ->
    'Elixir.AutomergeNif':doc_new().

-file("src/gleam_automerge.gleam", 21).
-spec load_doc(bitstring()) -> {ok, doc_ref()} | {error, automerge_error()}.
load_doc(Binary) ->
    _pipe = 'Elixir.AutomergeNif':doc_load(Binary),
    gleam@result:map_error(_pipe, fun(Field@0) -> {invalid_binary, Field@0} end).

-file("src/gleam_automerge.gleam", 27).
-spec save_doc(doc_ref()) -> bitstring().
save_doc(Doc) ->
    'Elixir.AutomergeNif':doc_save(Doc).

-file("src/gleam_automerge.gleam", 30).
-spec save_doc_incremental(doc_ref()) -> bitstring().
save_doc_incremental(Doc) ->
    'Elixir.AutomergeNif':doc_save_incremental(Doc).

-file("src/gleam_automerge.gleam", 33).
-spec get_json(doc_ref()) -> binary().
get_json(Doc) ->
    'Elixir.AutomergeNif':doc_get_json(Doc).

-file("src/gleam_automerge.gleam", 38).
-spec new_sync_state() -> sync_state_ref().
new_sync_state() ->
    'Elixir.AutomergeNif':sync_state_new().

-file("src/gleam_automerge.gleam", 43).
-spec generate_sync_message(doc_ref(), sync_state_ref()) -> gleam@option:option(bitstring()).
generate_sync_message(Doc, State) ->
    'Elixir.AutomergeNif':generate_sync_message(Doc, State).

-file("src/gleam_automerge.gleam", 55).
-spec receive_sync_message(doc_ref(), sync_state_ref(), bitstring()) -> {ok,
        bitstring()} |
    {error, automerge_error()}.
receive_sync_message(Doc, State, Msg) ->
    _pipe = 'Elixir.AutomergeNif':receive_sync_message(Doc, State, Msg),
    gleam@result:map_error(_pipe, fun(Field@0) -> {nif_error, Field@0} end).
