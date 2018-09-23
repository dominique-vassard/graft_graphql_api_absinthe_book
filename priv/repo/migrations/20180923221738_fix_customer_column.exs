defmodule PlateSlate.Repo.Migrations.FixCustomerColumn do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      remove(:ucstomer_id)
      add(:customer_id, references(:users))
    end
  end
end
