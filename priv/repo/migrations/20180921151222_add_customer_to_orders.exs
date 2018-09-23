defmodule PlateSlate.Repo.Migrations.AddCustomerToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add(:ucstomer_id, references(:users))
    end
  end
end
