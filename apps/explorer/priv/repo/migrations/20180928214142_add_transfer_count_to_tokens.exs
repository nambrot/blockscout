defmodule Explorer.Repo.Migrations.AddTransferCountToTokens do
  use Ecto.Migration

  def change do
    alter table("tokens") do
      add(:transfers_count, :bigint)
    end
  end
end
