defmodule DnsAdblocker.Providers do
  @moduledoc false

  use Agent

  @providers_url "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/pro.txt"

  @spec fetch() :: Enumerable.t()
  defp fetch() do
    %Finch.Response{body: providers_str} =
      Finch.build(:get, @providers_url) |> Finch.request!(MyFinch, [{:receive_timeout, 60_000}])

    providers_str
    |> String.split(~r{\r\n|\r|\n})
    |> Stream.filter(&(!String.starts_with?(&1, "#")))
  end

  @spec fetch_and_update() :: :ok
  def fetch_and_update() do
    IO.inspect("Fetching and updating agent...")

    Agent.update(__MODULE__, fn _ -> MapSet.new() end)

    providers = fetch()
      |> Enum.into(MapSet.new)

    Agent.update(__MODULE__, fn _ -> providers end)
  end

  def start_link(_initial_value) do
    Agent.start_link(fn -> MapSet.new() end, name: __MODULE__)
  end

  @spec has_provider?(String.t()) :: String.t()
  def has_provider?(provider) when is_binary(provider) do
    Agent.get(__MODULE__, fn providers -> MapSet.member?(providers, provider) end)
  end
end
