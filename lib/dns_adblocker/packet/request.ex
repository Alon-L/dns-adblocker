defmodule DnsAdblocker.Packet.Request do
  defstruct [:domain, :id, :client, :is_provider?, :is_question_cached?, :packet]

  alias DnsAdblocker.Packet.Utils
  alias DnsAdblocker.Packet.Request
  alias DnsAdblocker.Providers
  alias DnsAdblocker.TimedCache

  def init(
        {:dns_rec, {:dns_header, id, false, _, _, _, _, _, _, _}, questions, _, _, _} = packet,
        client
      ) do
    case questions do
      [{:dns_query, domain, _, _, _} = question] ->
        domain = to_string(domain)

        {:ok,
         %Request{
           domain: domain,
           id: id,
           client: client,
           is_provider?: is_provider?(domain),
           is_question_cached?: is_question_cached?(question),
           packet: packet
         }}

      _ ->
        # A query is invalid if it has more than one question. We just forward it.
        {:invalid, nil}
    end
  end

  def init(raw, client) when is_binary(raw) do
    {:ok, packet} = :inet_dns.decode(raw)
    init(packet, client)
  end

  def apply_invalid_answer(%Request{packet: packet} = req) do
    %Request{req | packet: Utils.apply_invalid_answer(packet)}
  end

  def apply_cached_answers(%Request{is_question_cached?: true, packet: packet} = req) do
    key = Utils.get_packet_question(packet) |> Utils.question_to_key()
    answers = TimedCache.get(:questions, key)
    %Request{req | packet: Utils.apply_answers(packet, answers)}
  end

  def to_response(%Request{packet: packet} = req) do
    %Request{req | packet: Utils.to_response(packet)}
  end

  def to_raw(%Request{packet: packet}) do
    Utils.to_raw(packet)
  end

  def cache_request(%Request{id: id, client: client}) do
    TimedCache.insert(:requests, id, client)
  end

  defp is_question_cached?(question) do
    TimedCache.member?(:questions, Utils.question_to_key(question))
  end

  defp is_provider?(domain) when is_binary(domain) do
    Providers.member?(domain)
  end
end
