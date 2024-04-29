defmodule DnsAdblocker.TimedCache do
  @moduledoc """
  A cache with an expiration for its keys.
  """
  alias DnsAdblocker.TimedCache

  @enforce_keys [:table]
  @type t() :: %TimedCache{table: atom(), max_ttl: integer(), tick: integer()}
  defstruct [:table, max_ttl: 60 * 60 * 1_000, tick: 5 * 60 * 1_000]

  use GenServer

  def start_link(%TimedCache{table: table} = state) do
    GenServer.start_link(__MODULE__, state, name: table)
  end

  @spec get(atom(), term()) :: term()
  def get(table, key) do
    GenServer.call(table, {:get, key})
  end

  @spec member?(atom(), term()) :: term()
  def member?(table, key) do
    GenServer.call(table, {:member, key})
  end

  @spec pop(atom(), term()) :: term()
  def pop(table, key) do
    GenServer.call(table, {:pop, key})
  end

  @spec insert(atom(), term(), term()) :: :ok
  def insert(table, key, value) do
    GenServer.cast(table, {:insert, key, value})
  end

  @impl true
  def init(%TimedCache{table: table, tick: tick} = state) do
    :timer.send_interval(tick, {:tick})

    :ets.new(table, [:named_table, :set, :public])
    {:ok, state}
  end

  @impl true
  def handle_call({:get, key}, _from, %TimedCache{table: table} = state) do
    [{^key, value, _time}] = :ets.lookup(table, key)
    {:reply, value, state}
  end

  @impl true
  def handle_call({:member, key}, _from, %TimedCache{table: table} = state) do
    member? = :ets.member(table, key)
    {:reply, member?, state}
  end

  @impl true
  def handle_call({:pop, key}, _from, %TimedCache{table: table} = state) do
    case :ets.take(table, key) do
      [{^key, value, _time} | _] -> {:reply, value, state}
      _ -> {:reply, nil, state}
    end
  end

  @impl true
  def handle_cast({:insert, key, value}, %TimedCache{table: table} = state) do
    time = DateTime.to_unix(DateTime.utc_now())
    :ets.insert(table, {key, value, time})
    {:noreply, state}
  end

  @impl true
  def handle_info({:tick}, %TimedCache{table: table, max_ttl: max_ttl} = state) do
    time = DateTime.to_unix(DateTime.utc_now())
    :ets.select_delete(table, [{{:_, :_, :"$1"}, [{:>, {:-, time, :"$1"}, max_ttl}], [true]}])
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, table) do
    :ets.delete(table)
    :ok
  end
end
