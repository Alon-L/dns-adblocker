defmodule DnsAdblocker do
  use Application

  def start(_type, _args) do
    children = [
      {Finch, name: MyFinch},
      {DnsAdblocker.Providers.Scheduler, name: Scheduler},
    ]

    DnsAdblocker.Requests.start()

    {remote_dns_ip, remote_dns_port} = DnsAdblocker.RemoteAddr.get_remote_dns_addr()

    Supervisor.start_link(children, strategy: :one_for_all)

    {:ok, local_server} = :gen_udp.open(53, [:binary, {:active, true}])
    {:ok, remote_server} = :gen_udp.open(0, [:binary, {:active, true}])

    :ok = :gen_udp.connect(remote_server, remote_dns_ip, remote_dns_port)

    IO.puts("Running!")

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
              |> DnsAdblocker.Requests.put({ip, port})

              :gen_udp.send(remote_server, packet)
            else
              :gen_udp.send(local_server, ip, port, DnsAdblocker.Packet.invalid_response(packet))
            end
          else
            DnsAdblocker.Packet.get_transaction_id(packet)
            |> DnsAdblocker.Requests.put({ip, port})

            :gen_udp.send(remote_server, packet)
          end
        end)

      {:udp, ^remote_server, _ip, _port, packet} ->
        spawn(fn ->
          {ip, port} =
            DnsAdblocker.Packet.get_transaction_id(packet)
            |> DnsAdblocker.Requests.pop()

          :gen_udp.send(local_server, ip, port, packet)
        end)

      _ ->
        IO.puts("Unknown message")
    end

    listen(local_server, remote_server, map)
  end
end
