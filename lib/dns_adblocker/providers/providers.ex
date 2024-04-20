defmodule DnsAdblocker.Providers do
  @moduledoc """
  Use erlang's ETS to store a set of all the providers' DNSs.

  Fetch the providers from the @providers_url list.
  The list is updated every day, and the Providers Scheduler updates the ETS.
  """

  @providers_url "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/pro.txt"

  def start() do
    :ets.new(:providers, [:named_table, :set, :public])
  end

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
    IO.puts("Fetching and updating providers...")

    :ets.delete_all_objects(:providers)

    providers =
      fetch()
      |> Stream.map(&({&1}))
      |> Enum.to_list()

    true = :ets.insert(:providers, providers)

    IO.puts("Finished fetching and updating providers")
  end

  @spec has_provider?(String.t()) :: String.t()
  def has_provider?(provider) when is_binary(provider) do
    :ets.member(:providers, provider)
  end
end
