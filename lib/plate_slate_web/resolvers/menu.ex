defmodule PlateSlateWeb.Resolvers.Menu do
  import Absinthe.Resolution.Helpers, only: [async: 1]
  alias PlateSlate.Menu

  def menu_items(_, args, _) do
    {:ok, Menu.list_items(args)}
  end

  def items_for_category(category, _, _) do
    query = Ecto.assoc(category, :items)
    {:ok, PlateSlate.Repo.all(query)}
  end

  def search(_, %{matching: term}, _) do
    {:ok, Menu.search(term)}
  end

  def create_item(_, %{input: params}, _) do
    with {:ok, item} <- Menu.create_item(params) do
      {:ok, %{menu_item: item}}
    end
  end

  def category_for_item(item, _, _) do
    async(fn ->
      query = Ecto.assoc(item, :category)
      {:ok, PlateSlate.Repo.one(query)}
    end)
    |> IO.inspect()
  end
end
