defmodule ProcomWeb.PageController do
  use ProcomWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
