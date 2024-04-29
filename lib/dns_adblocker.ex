defmodule DnsAdblocker do
  use Application

  def start(_type, _args) do
    children = [
      {Finch, name: MyFinch},
      DnsAdblocker.Providers,
      %{id: DnsAdblocker.Socket.Local, start: {DnsAdblocker.Socket.Local, :start_link, [[]]}},
      %{id: DnsAdblocker.Socket.Remote, start: {DnsAdblocker.Socket.Remote, :start_link, [[]]}},
      %{
        id: :questions,
        start:
          {DnsAdblocker.TimedCache, :start_link, [%DnsAdblocker.TimedCache{table: :questions}]}
      },
      %{
        id: :requests,
        start:
          {DnsAdblocker.TimedCache, :start_link, [%DnsAdblocker.TimedCache{table: :requests}]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)

    IO.puts("Starting...")

    wait()
  end

  def wait() do
    receive do
      msg -> IO.inspect(msg)
    end

    wait()
  end
end
