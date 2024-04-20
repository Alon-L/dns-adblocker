defmodule DnsAdblocker.Requests do
  @moduledoc false

  def start() do
    :ets.new(:requests, [:named_table, :set, :public])
  end

  def pop(key) do
    case :ets.take(:requests, key) do
      [{^key, value} | _] -> value
      _ -> nil
    end
  end

  def put(key, value) do
    :ets.insert(:requests, {key, value})
  end
end
