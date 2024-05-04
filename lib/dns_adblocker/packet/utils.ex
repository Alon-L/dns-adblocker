defmodule DnsAdblocker.Packet.Utils do
  @moduledoc false

  @invalid_answer_ttl 99999
  @invalid_answer_ip {0, 0, 0, 0}

  def to_raw(packet) do
    :inet_dns.encode(packet)
  end

  def to_response({:dns_rec, header, _, _, _, _} = packet) do
    res_header = put_elem(header, 2, true)
    put_elem(packet, 1, res_header)
  end

  def apply_invalid_answer({:dns_rec, _, [question], _, _, _} = packet) do
    {:dns_query, domain, _type, class, _} = question

    answer =
      {:dns_rr, domain, :a, class, 0, @invalid_answer_ttl, @invalid_answer_ip, nil, [], false}

    apply_answers(packet, {[answer], []})
  end

  def apply_answers({:dns_rec, _, _, _, _, _} = packet, {answers, nameservers}) do
    packet
    |> put_elem(3, answers)
    |> put_elem(4, nameservers)
  end

  def get_packet_answers({:dns_rec, _, _, answers, nameservers, _}) do
    {answers, nameservers}
  end

  def get_packet_question({:dns_rec, _, [question], _, _, _}) do
    question
  end

  def question_to_key({:dns_query, domain, type, class, _}) do
    {domain, type, class}
  end

  def packet_to_raw(packet) do
    :inet_dns.encode(packet)
  end
end
