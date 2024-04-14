defmodule DnsAdblocker.Packet do
  @moduledoc false

  @dns_header_id_offset 0
  @dns_header_flags_offset 16
  @dns_header_num_questions_offset 32

  @dns_qr_offset @dns_header_flags_offset
  @dns_qr_size 1

  @dns_opcode_offset @dns_header_flags_offset + 1
  @dns_opcode_size 4

  @dns_rcode_offset @dns_header_flags_offset + 12
  @dns_rcode_size 4

  @dns_num_questions_size 16

  @dns_question_offset @dns_header_num_questions_offset + 4 * 16

  @spec is_query?(binary()) :: bool
  def is_query?(
        <<_::size(@dns_qr_offset), qr::size(@dns_qr_size), opcode::size(@dns_opcode_size),
          _::bitstring>>
      ) do
    qr == 0 && opcode == 0
  end

  @spec is_one_question?(binary()) :: bool
  def is_one_question?(
        <<_::size(@dns_header_num_questions_offset), num_questions::size(@dns_num_questions_size),
          _::bitstring>>
      ) do
    num_questions == 1
  end

  @doc """
  Return a list of the question's parts.

  Should probably be joined by Enum.join(2).
  """
  @spec get_question(binary()) :: bool
  def get_question(<<before::bitstring-size(@dns_question_offset), rest::bitstring>>) do
    case rest do
      <<0::size(8), _::bitstring>> ->
        []

      <<len::size(8), label::binary-size(len), question_rest::bitstring>> ->
        [label] ++ get_question(before <> question_rest)
    end
  end
end
