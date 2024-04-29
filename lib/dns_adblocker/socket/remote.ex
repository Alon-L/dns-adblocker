defmodule DnsAdblocker.Socket.Remote do
  @moduledoc false

  alias DnsAdblocker.Packet.Response
  alias DnsAdblocker.Socket
  @behaviour Socket

  @remote_port Application.compile_env!(:dns_adblocker, :remote_dns_port)
  @remote_ip Application.compile_env!(:dns_adblocker, :remote_dns_ip)
             |> :inet.parse_address()
             |> elem(1)

  def start_link(_) do
    Socket.start_link(__MODULE__, remote_addr: {@remote_ip, @remote_port})
  end

  @impl true
  def recv(_socket, _ip, _port, packet) do
    spawn(fn ->
      case Response.init(packet) do
        {:ok, res} -> handle_response(res)
        _ -> :error
      end
    end)

    :ok
  end

  def handle_response(%Response{is_request_cached?: true} = res) do
    Response.cache_answers(res)
    {ip, port} = Response.pop_response_client(res)
    Socket.send(Socket.Local, ip, port, Response.to_raw(res))
  end
end
