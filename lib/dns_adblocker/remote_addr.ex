defmodule DnsAdblocker.RemoteAddr do
  @moduledoc """
  Returns the IP address and port of the real remote DNS server.

  The :remote_dns_addr env variable contains a string formatted representation of the remote DNS server.
  """

  @type ip_tuple() :: {byte(), byte(), byte(), byte()}
  @spec get_remote_dns_addr() :: {ip_tuple(), integer()}
  def get_remote_dns_addr() do
    {:ok, ip} = Application.fetch_env!(:dns_adblocker, :remote_dns_ip) |> :inet.parse_address
    port = Application.fetch_env!(:dns_adblocker, :remote_dns_port)
    {ip, port}
  end
end
