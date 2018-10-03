defmodule Explorer.Counter.TokenTest do
  use Explorer.DataCase

  alias Explorer.Counter

  describe "init/1" do
    test "creates an 'token_counts' ets table" do
      Counter.Token.init(:ok)

      refute :ets.whereis(Counter.Token.table_name()) == :undefined
    end

    test "loads the token's transfers consolidate info" do
      token_contract_address = insert(:contract_address)
      token = insert(:token, contract_address: token_contract_address)

      transaction =
        :transaction
        |> insert()
        |> with_block()

      insert(
        :token_transfer,
        to_address: build(:address),
        transaction: transaction,
        token_contract_address: token_contract_address,
        token: token
      )

      insert(
        :token_transfer,
        to_address: build(:address),
        transaction: transaction,
        token_contract_address: token_contract_address,
        token: token
      )

      :ets.delete(Counter.Token.table_name())

      Counter.Token.init(:ok)

      assert Counter.Token.fetch(token.contract_address_hash) == 2
    end

    test "subscribes to 'token_transfers' events" do
      Counter.Token.init(:ok)

      current_pid = self()

      assert [{^current_pid, _}] = Registry.lookup(Registry.ChainEvents, :token_transfers)
    end
  end

  describe "fetch/1" do
    test "fetchs the total token transfers by token contract address hash" do
      token_contract_address = insert(:contract_address)
      token = insert(:token, contract_address: token_contract_address)

      Counter.Token.insert({token.contract_address_hash, 15})

      assert Counter.Token.fetch(token.contract_address_hash) == 15
    end
  end

  describe "handle_info/2" do
    test "updates the number of token transfers of a token" do
      token_contract_address = insert(:contract_address)
      token = insert(:token, contract_address: token_contract_address)

      transaction =
        :transaction
        |> insert()
        |> with_block()

      token_transfer =
        insert(
          :token_transfer,
          to_address: build(:address),
          transaction: transaction,
          token_contract_address: token_contract_address,
          token: token
        )

      Counter.Token.handle_info({:chain_event, :token_transfers, :realtime, [token_transfer]}, :ok)

      assert Counter.Token.fetch(token.contract_address_hash) == 1
    end
  end
end
