defmodule DnsAdblocker.Providers.Scheduler do
  @moduledoc false

  use GenServer

  @fetch_interval 24 * 60 * 60 * 1_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Task.start(&DnsAdblocker.Providers.fetch_and_update/0)

    :timer.send_interval(@fetch_interval, :exec)
    {:ok, state}
  end

  def handle_info(:exec, state) do
    Task.start(&DnsAdblocker.Providers.fetch_and_update/0)
    {:noreply, state}
  end
end
