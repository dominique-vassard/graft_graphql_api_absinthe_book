defmodule PlateSlateWeb.Schema.Subscription.NewOrderTest do
  use PlateSlateWeb.SubscriptionCase

  alias PlateSlateWeb.Support.Factory

  @login """
  mutation ($email: String!, $role: Role!) {
    login(role: $role, password: "super-secret", email: $email) {
      token
    }
  }
  """
  @subscription """
  subscription {
    newOrder {
      customerNumber
    }
  }
  """
  @mutation """
  mutation ($input:PlaceOrderInput) {
    placeOrder(input: $input) {
      order {
        id
      }
    }
  }
  """
  test "new orders can be subscribed to", %{socket: socket} do
    # Login
    user = Factory.create_user("employee")

    ref =
      push_doc(socket, @login,
        variables: %{
          email: user.email,
          role: "EMPLOYEE"
        }
      )

    assert_reply(ref, :ok, %{data: %{"login" => %{"token" => _}}}, 1000)

    # setup subscription
    ref = push_doc(socket, @subscription)
    assert_reply(ref, :ok, %{subscriptionId: subscription_id})

    # run a mutation to trigger the subscription
    order_input = %{
      "customerNumber" => 24,
      "items" => [
        %{"quantity" => 2, "menuItemId" => menu_item("Reuben").id}
      ]
    }

    ref = push_doc(socket, @mutation, variables: %{"input" => order_input})
    assert_reply(ref, :ok, reply)
    assert %{data: %{"placeOrder" => %{"order" => %{"id" => _}}}} = reply

    # chek to see if we got subscription data
    expected = %{
      result: %{data: %{"newOrder" => %{"customerNumber" => 24}}},
      subscriptionId: subscription_id
    }

    assert_push("subscription:data", push)
    assert expected == push
  end

  test "customers can't see other customer orders", %{socket: socket} do
    customer1 = Factory.create_user("customer")
    # Login as customer 1
    ref =
      push_doc(socket, @login,
        variables: %{
          email: customer1.email,
          role: "CUSTOMER"
        }
      )

    assert_reply(ref, :ok, %{data: %{"login" => %{"token" => _}}}, 1000)

    # suscribe ro orders
    ref = push_doc(socket, @subscription)
    assert_reply(ref, :ok, %{subscriptionId: _subscription_id})

    # Customer1 places order
    place_order(customer1)
    assert_push("subscription:data", _)

    # Customer2 places order
    customer2 = Factory.create_user("customer")
    place_order(customer2)
    refute_receive _
  end

  defp place_order(customer) do
    order_input = %{
      "customerNumber" => 24,
      "items" => [
        %{"quantity" => 2, "menuItemId" => menu_item("Reuben").id}
      ]
    }

    %{data: %{"placeOrder" => _}} =
      Absinthe.run!(@mutation, PlateSlateWeb.Schema,
        context: %{current_user: customer},
        variables: %{"input" => order_input}
      )
  end
end
