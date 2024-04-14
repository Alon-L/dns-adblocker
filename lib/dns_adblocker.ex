defmodule DnsAdblocker do
  use Application

  @remote_dns_addr {"82.102.139.10", 53}

  def start(_type, _args) do
    children = [
      {Finch, name: MyFinch},
      {DnsAdblocker.Providers, name: Providers}
    ]

    Supervisor.start_link(children, strategy: :one_for_all)

    local_server = Socket.UDP.open!(53)
    remote_server = Socket.UDP.open!()

    Task.start(&DnsAdblocker.Providers.fetch_and_update/0)

    IO.inspect("Running!")

    listen(local_server, remote_server)
  end

  def listen(local_server, remote_server) do
    {data, client} = local_server |> Socket.Datagram.recv!()

    spawn(fn ->
      remote_server |> Socket.Datagram.send!(data, @remote_dns_addr)
      {res, _} = remote_server |> Socket.Datagram.recv!()

      local_server |> Socket.Datagram.send!(res, client)

      if DnsAdblocker.Packet.is_query?(data) && DnsAdblocker.Packet.is_one_question?(data) do
        question =
          DnsAdblocker.Packet.get_question(data)
          |> Enum.join(".")

        if !DnsAdblocker.Providers.has_provider?(question) do
          remote_server |> Socket.Datagram.send!(data, @remote_dns_addr)
          {res, _} = remote_server |> Socket.Datagram.recv!()

          local_server |> Socket.Datagram.send!(res, client)
        end
      end
    end)

    listen(local_server, remote_server)
  end
end
