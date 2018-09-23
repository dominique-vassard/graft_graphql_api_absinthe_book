defmodule PlateSlateWeb.Resolvers.Accounts do
  alias PlateSlate.Accounts

  def login(_, %{email: email, password: password, role: role}, _) do
    case Accounts.authenticate(role, email, password) do
      {:ok, user} ->
        token = PlateSlateWeb.Authentication.sign(%{role: role, id: user.id})
        {:ok, %{token: token, user: user}}

      _ ->
        {:error, "Incorrect email or password"}
    end
  end

  def me(_, _, %{context: %{current_user: user}}) do
    {:ok, user}
  end

  def me(_, _, _) do
    {:ok, nil}
  end
end
