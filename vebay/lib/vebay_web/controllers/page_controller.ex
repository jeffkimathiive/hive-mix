defmodule VebayWeb.PageController do
  use VebayWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
