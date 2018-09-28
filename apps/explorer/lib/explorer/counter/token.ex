defmodule Explorer.Counter.Token do
  use GenServer

  @moduledoc """
  Counts the Token transfers and addresses involved.
  """

  alias Explorer.Chain
  alias Explorer.Chain.TokenTransfer

  @table :token_counts

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
    :ets.new(@table, [:set, :named_table, :protected])

    consolidate(TokenTransfer.count_token_transfers())

    Chain.subscribe_to_events(:token_transfers)
IO.inspect "mama mia"
    {:ok, args}
  end

  def consolidate(items) do
    for item <- items do
      :ets.insert(@table, item)
    end
  end

  def fetch(token_hash) do
    :ets.lookup(@table, token_hash)
  end

  def update(token_hash, transfers) do
    :ets.insert(@table, {token_hash, transfers})
  end

  @impl true
  def handle_info({:chain_event, :token_transfers, :catchup, token_transfers}, state) do
    # [
    #   %Explorer.Chain.TokenTransfer{
    #     __meta__: #Ecto.Schema.Metadata<:loaded, "token_transfers">,
    #     amount: #Decimal<5000000000000000000000000>,
    #     from_address: #Ecto.Association.NotLoaded<association :from_address is not loaded>,
    #     from_address_hash: %Explorer.Chain.Hash{
    #       byte_count: 20,
    #       bytes: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    #     },
    #     id: 1,
    #     inserted_at: ~N[2018-10-02 23:03:38.515465],
    #     log_index: 1,
    #     to_address: #Ecto.Association.NotLoaded<association :to_address is not loaded>,
    #     to_address_hash: %Explorer.Chain.Hash{
    #       byte_count: 20,
    #       bytes: <<213, 183, 170, 13, 37, 230, 114, 214, 245, 233, 17, 139, 197,
    #         191, 19, 1, 27, 149, 143, 145>>
    #     },
    #     token: #Ecto.Association.NotLoaded<association :token is not loaded>,
    #     token_contract_address: #Ecto.Association.NotLoaded<association :token_contract_address is not loaded>,
    #     token_contract_address_hash: %Explorer.Chain.Hash{
    #       byte_count: 20,
    #       bytes: <<160, 240, 69, 30, 152, 150, 132, 13, 154, 76, 206, 224, 71, 139,
    #         222, 230, 247, 200, 143, 223>>
    #     },
    #     token_id: nil,
    #     transaction: #Ecto.Association.NotLoaded<association :transaction is not loaded>,
    #     transaction_hash: %Explorer.Chain.Hash{
    #       byte_count: 32,
    #       bytes: <<220, 40, 253, 35, 129, 145, 212, 35, 146, 74, 12, 116, 207, 141,
    #         24, 80, 159, 244, 182, 72, 142, 247, 176, 5, 87, 123, 12, 123, 202, 158,
    #         122, 121>>
    #     },
    #     updated_at: ~N[2018-10-02 23:03:38.515465]
    #   }
    # ]

    {:noreply, state}
  end

  @impl true
  def handle_info({:chain_event, :token_transfers, :realtime, token_transfers}, state) do


    {:noreply, state}
  end
end
