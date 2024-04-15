defmodule DnsAdblocker.TransactionsMap do
  @moduledoc false

  use Agent

  def start_link(_initial_value) do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  def pop(key) do
    Agent.get_and_update(__MODULE__, &Map.pop(&1, key))
  end

  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end
end
