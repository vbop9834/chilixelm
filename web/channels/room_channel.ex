defmodule Chilixelm.RoomChannel do
  use Chilixelm.Web, :channel

  def join("room:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("new:msg", %{"body" => body, "user" => user}, socket) do
    IO.puts "hmm"
    broadcast socket, "new:msg", %{body: body, user: user}
    {:noreply, socket}
  end

  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
