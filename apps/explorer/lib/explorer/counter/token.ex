defmodule Explorer.Counter.Token do
  use GenServer

  @moduledoc """
  Counts the Token transfers and addresses involved.
  """

  alias Explorer.Chain
  alias Explorer.Chain.TokenTransfer

  @table :token_counts

  def table_name() do
    @table
  end

  @doc """
  Starts a process to continually monitor the token counters.
  """
  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## Server
  @impl true
  def init(args) do
    :ets.new(table_name(), [:set, :named_table, :protected])

    consolidate(TokenTransfer.count_token_transfers())

    Chain.subscribe_to_events(:token_transfers)

    {:ok, args}
  end

  defp consolidate(items) do
    for item <- items do
      insert(item)
    end
  end

  def insert({token_hash, counter}) do
    :ets.insert(table_name(), {to_string(token_hash), counter})
  end

  def fetch(token_hash) do
    result = :ets.lookup(table_name(), to_string(token_hash))

    elem(List.first(result), 1)
  end

  @impl true
  def handle_info({:chain_event, :token_transfers, _type, token_transfers}, state) do
    token_transfers
    |> Enum.map(& &1.token_contract_address_hash)
    |> Enum.each(&update_counter/1)

    {:noreply, state}
  end

  defp update_counter(token_hash) do
    default = {to_string(token_hash), 0}

    :ets.update_counter(table_name(), to_string(token_hash), 1, default)
  end
end
