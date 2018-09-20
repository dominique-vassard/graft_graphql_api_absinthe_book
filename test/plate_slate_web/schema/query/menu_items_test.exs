# ---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
# ---
defmodule PlateSlateWeb.Schema.Query.MenuItemsTest do
  use PlateSlateWeb.ConnCase, async: true

  setup do
    PlateSlate.Seeds.run()
  end

  @query """
  {
    menuItems (filter: {}) {
      name
    }
  }
  """
  test "menuItems field returns menu items" do
    conn = build_conn()
    conn = get(conn, "/api", query: @query)

    assert json_response(conn, 200) == %{
             "data" => %{
               "menuItems" => [
                 %{"name" => "Bánh mì"},
                 %{"name" => "Chocolate Milkshake"},
                 %{"name" => "Croque Monsieur"},
                 %{"name" => "French Fries"},
                 %{"name" => "Lemonade"},
                 %{"name" => "Masala Chai"},
                 %{"name" => "Muffuletta"},
                 %{"name" => "Papadum"},
                 %{"name" => "Pasta Salad"},
                 %{"name" => "Reuben"},
                 %{"name" => "Soft Drink"},
                 %{"name" => "Vada Pav"},
                 %{"name" => "Vanilla Milkshake"},
                 %{"name" => "Water"}
               ]
             }
           }
  end

  @query """
  {menuItems (filter: {name: "reu"}) {
    name
    }
  }
  """
  test "menuItems field returns menu items filtered by name" do
    response = get(build_conn(), "/api", query: @query)

    assert json_response(response, 200) == %{
             "data" => %{
               "menuItems" => [
                 %{"name" => "Reuben"}
               ]
             }
           }
  end

  @query """
  {menuItems (filter: {name: 123}) {
    name
    }
  }
  """
  test "menuItems field returns error when using bad value" do
    response = get(build_conn(), "/api", query: @query)

    assert %{
             "errors" => [
               %{"message" => message}
             ]
           } = json_response(response, 400)

    assert message = "Argument \"matching\" has invalid value 123."
  end

  @query """
  query($term: String) {
  menuItems (filter: {name: $term}) {
    name
    }
  }
  """
  @variables %{"term" => "reu"}
  test "menuItems field returns menu items filtered by name (with variable)" do
    response = get(build_conn(), "/api", query: @query, variables: @variables)

    assert json_response(response, 200) == %{
             "data" => %{
               "menuItems" => [
                 %{"name" => "Reuben"}
               ]
             }
           }
  end

  @query """
  {
    menuItems(order: DESC, filter: {}) {
      name
    }
  }
  """
  test "menuItems field returns items descending using literals" do
    response = get(build_conn(), "/api", query: @query)

    assert %{
             "data" => %{
               "menuItems" => [
                 %{"name" => "Water"} | _
               ]
             }
           } = json_response(response, 200)
  end

  @query """
  query ($order: SortOrder!) {
    menuItems(order: $order, filter: {}) {
      name
    }
  }
  """
  @variables %{"order" => "DESC"}
  test "menuItems field returns items descending using variables" do
    response = get(build_conn(), "/api", query: @query, variables: @variables)

    assert %{
             "data" => %{
               "menuItems" => [
                 %{"name" => "Water"} | _
               ]
             }
           } = json_response(response, 200)
  end

  @query """
  {
    menuItems(filter: {category: "Sandwiches", tag: "Vegetarian"}) {
      name
    }
  }
  """
  test "menuItems returns menu items, filtering with a literal" do
    response = get(build_conn(), "/api", query: @query)

    assert %{"data" => %{"menuItems" => [%{"name" => "Vada Pav"}]}} ==
             json_response(response, 200)
  end

  @query """
  query ($filter: MenuItemFilter) {
    menuItems(filter: $filter) {
      name
    }
  }
  """
  @variables %{"filter" => %{"category" => "Sandwiches", "tag" => "Vegetarian"}}
  test "menuItems returns menu items, filtering with variables" do
    response = get(build_conn(), "/api", query: @query, variables: @variables)

    assert %{"data" => %{"menuItems" => [%{"name" => "Vada Pav"}]}} ==
             json_response(response, 200)
  end

  @query """
  query ($filter: MenuItemFilter!) {
    menuItems (filter: $filter) {
      name
      addedOn
    }
  }
  """
  @variables %{filter: %{"addedBefore" => "2017-01-20"}}
  test "menuItems filtered with a custom scalar" do
    sides = PlateSlate.Repo.get_by!(PlateSlate.Menu.Category, name: "Sides")

    %PlateSlate.Menu.Item{
      name: "Garlic Fries",
      added_on: ~D[2017-01-01],
      price: 2.50,
      category: sides
    }
    |> PlateSlate.Repo.insert!()

    response = get(build_conn(), "/api", query: @query, variables: @variables)

    assert %{"data" => %{"menuItems" => [%{"name" => "Garlic Fries", "addedOn" => "2017-01-01"}]}} ==
             json_response(response, 200)
  end

  @query """
  query ($filter: MenuItemFilter!) {
    menuItems(filter: $filter) {
      name
    }
  }
  """
  @variables %{filter: %{"addedBefore" => "invalid-date"}}
  test "menuItems filtered by custom scalr with error" do
    response = get(build_conn(), "/api", query: @query, variables: @variables)

    assert %{
             "errors" => [%{"locations" => [%{"column" => 0, "line" => 2}], "message" => message}]
           } = json_response(response, 400)

    expected = """
    Argument "filter" has invalid value $filter.
    In field "addedBefore": Expected type "Date", found "invalid-date".
    """

    assert expected == message <> "\n"
  end

  @query """
  query Search($term: String!) {
    search(matching: $term) {
      ...on MenuItem{
        name
      }
      ...on Category {
        name
      }
      __typename
    }
  }
  """
  @variables %{term: "e"}
  test "search returns a list of menu items and categories" do
    response = get(build_conn(), "/api", query: @query, variables: @variables)

    assert %{"data" => %{"search" => results}} = json_response(response, 200)
    assert length(results) > 0
    assert Enum.find(results, &(&1["__typename"] == "Category"))
    assert Enum.find(results, &(&1["__typename"] == "MenuItem"))
  end

  @query """
  query Search($term: String!) {
    search(matching: $term) {
      name
      __typename
    }
  }
  """
  @variables %{term: "e"}
  test "search returns a list of menu items and categories (name only)" do
    response = get(build_conn(), "/api", query: @query, variables: @variables)

    assert %{"data" => %{"search" => results}} = json_response(response, 200)
    assert length(results) > 0
    assert Enum.find(results, &(&1["__typename"] == "Category"))
    assert Enum.find(results, &(&1["__typename"] == "MenuItem"))
    assert Enum.all?(results, & &1["name"])
  end
end
