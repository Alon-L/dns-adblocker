defmodule DnsAdblocker.Socket.Local do
  @moduledoc false

  alias DnsAdblocker.Packet.Request
  alias DnsAdblocker.Socket
  @behaviour Socket

  def start_link(_) do
    Socket.start_link(__MODULE__, local_port: 53)
  end

  @impl true
  def recv(_socket, ip, port, raw) do
    spawn(fn ->
      case Request.init(raw, {ip, port}) do
        {:ok, req} -> handle_request(req)
        _ -> :error
      end
    end)

    :ok
  end

  def handle_request(%Request{is_question_cached?: true} = req) do
    send_req(Socket.Local, Request.apply_cached_answers(req) |> Request.to_response())
  end

  def handle_request(%Request{is_provider?: true} = req) do
    send_req(Socket.Local, Request.apply_invalid_answer(req) |> Request.to_response())
  end

  def handle_request(%Request{} = req) do
    Request.cache_request(req)
    send_req(Socket.Remote, req)
  end

  defp send_req(socket, %Request{client: {ip, port}} = req) do
    Socket.send(socket, ip, port, Request.to_raw(req))
    :ok
  end
end
