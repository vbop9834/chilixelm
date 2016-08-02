defmodule Chilixelm.PageController do
  use Chilixelm.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
