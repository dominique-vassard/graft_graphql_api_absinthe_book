defmodule PlateSlateWeb.Context do
  @behaviour Plug
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _) do
    context = build_context(conn)
    # IO.inspect(context: context)
    Absinthe.Plug.put_options(conn, context: context)
  end

  def build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, data} = PlateSlateWeb.Authentication.verify(token),
         %{} = user <- get_user(data) do
      %{current_user: user}
    else
      _ -> %{}
    end
  end

  def get_user(%{id: id, role: role}) do
    PlateSlate.Accounts.lookup(id, role)
  end
end
