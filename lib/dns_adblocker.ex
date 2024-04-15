defmodule DnsAdblocker do
  use Application

  @remote_dns_addr {82, 102, 139, 10}
  @remote_dns_port 53

  def start(_type, _args) do
    children = [
      {Finch, name: MyFinch},
      {DnsAdblocker.Providers, name: Providers},
      {DnsAdblocker.Providers.Scheduler, name: Scheduler},
      {DnsAdblocker.TransactionsMap, name: TransactionsMap}
    ]

    Supervisor.start_link(children, strategy: :one_for_all)

    {:ok, local_server} = :gen_udp.open(53, [:binary, {:active, true}])
    {:ok, remote_server} = :gen_udp.open(0, [:binary, {:active, true}])

    :ok = :gen_udp.connect(remote_server, @remote_dns_addr, @remote_dns_port)

    IO.inspect("Running!")

    listen(local_server, remote_server, Map.new())
  end

  def listen(local_server, remote_server, map) do
    receive do
      {:udp, ^local_server, ip, port, packet} ->
        spawn(fn ->
          if DnsAdblocker.Packet.is_query?(packet) && DnsAdblocker.Packet.is_one_question?(packet) do
            question =
              DnsAdblocker.Packet.get_question(packet)
              |> Enum.join(".")

            if !DnsAdblocker.Providers.has_provider?(question) do
              DnsAdblocker.Packet.get_transaction_id(packet)
              |> DnsAdblocker.TransactionsMap.put({ip, port})

              :gen_udp.send(remote_server, packet)
            else
              :gen_udp.send(local_server, ip, port, DnsAdblocker.Packet.invalid_response(packet))
            end
          else
            DnsAdblocker.Packet.get_transaction_id(packet)
            |> DnsAdblocker.TransactionsMap.put({ip, port})

            :gen_udp.send(remote_server, packet)
          end
        end)

      {:udp, ^remote_server, _ip, _port, packet} ->
        spawn(fn ->
          {ip, port} =
            DnsAdblocker.Packet.get_transaction_id(packet)
            |> DnsAdblocker.TransactionsMap.pop()

          :gen_udp.send(local_server, ip, port, packet)
        end)

      _ ->
        IO.puts("Unknown message")
    end

    listen(local_server, remote_server, map)
  end
end
