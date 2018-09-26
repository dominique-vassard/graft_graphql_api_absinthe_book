defmodule PlateSlate.Repo.Migrations.CreateOrderItemView do
  use Ecto.Migration

  def up do
    execute("""
    CREATE VIEW order_item AS
      SELECT
        i.*, o.id AS order_id
      FROM orders AS o, jsonb_to_recordset(o.items) AS i(name text, quantity int, price float, id text)
    """)
  end

  def down do
    execute("DROP VIEW order_item")
  end
end
