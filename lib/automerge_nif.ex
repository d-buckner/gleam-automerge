defmodule AutomergeNif do
  @version Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :automerge,
    crate: :automerge_nif,
    base_url:
      "https://github.com/d-buckner/gleam-automerge/releases/download/v#{@version}",
    version: @version,
    targets: ~w[
      x86_64-unknown-linux-gnu
      aarch64-unknown-linux-gnu
      x86_64-apple-darwin
      aarch64-apple-darwin
    ],
    force_build: System.get_env("AUTOMERGE_BUILD") in ["1", "true"] or Mix.env() == :dev

  def doc_new(), do: :erlang.nif_error(:nif_not_loaded)
  def doc_load(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def doc_save(_doc), do: :erlang.nif_error(:nif_not_loaded)
  def doc_save_incremental(_doc), do: :erlang.nif_error(:nif_not_loaded)
  def doc_get_json(_doc), do: :erlang.nif_error(:nif_not_loaded)
  def sync_state_new(), do: :erlang.nif_error(:nif_not_loaded)
  def generate_sync_message(_doc, _state), do: :erlang.nif_error(:nif_not_loaded)
  def receive_sync_message(_doc, _state, _msg), do: :erlang.nif_error(:nif_not_loaded)
end
