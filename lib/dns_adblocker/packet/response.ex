defmodule DnsAdblocker.Packet.Response do
  defstruct [:id, :is_request_cached?, :packet]

  alias DnsAdblocker.Packet.Utils
  alias DnsAdblocker.Packet.Response
  alias DnsAdblocker.TimedCache

  def init({:dns_rec, {:dns_header, id, true, _, _, _, _, _, _, _}, questions, _, _, _} = packet) do
    case questions do
      [{:dns_query, _, _, _, _}] ->
        {:ok,
         %Response{
           id: id,
           is_request_cached?: is_request_cached?(id),
           packet: packet
         }}

      _ ->
        # A response is invalid if it has more than one question. We just forward it.
        {:invalid, nil}
    end
  end

  def init(raw) when is_binary(raw) do
    {:ok, packet} = :inet_dns.decode(raw)
    init(packet)
  end

  def cache_answers(%Response{packet: packet}) do
    key = Utils.get_packet_question(packet) |> Utils.question_to_key()
    answers = Utils.get_packet_answers(packet)
    TimedCache.insert(:questions, key, answers)
  end

  def to_raw(%Response{packet: packet}) do
    Utils.to_raw(packet)
  end

  def pop_response_client(%Response{id: id}) do
    TimedCache.pop(:requests, id)
  end

  defp is_request_cached?(id) do
    TimedCache.member?(:requests, id)
  end
end
