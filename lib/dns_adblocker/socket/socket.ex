defmodule DnsAdblocker.Socket do
  @moduledoc false

  @type ip_tuple() :: {byte(), byte(), byte(), byte()}

  @callback recv(:gen_udp.socket(), :inet.ip_address(), :inet.port_number(), binary()) :: :ok

  @default_local_port 0

  use GenServer

  def start_link(module, opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, {module, opts}, name: module)
  end

  def send(module, packet) do
    GenServer.cast(module, {:send, packet})
  end

  def send(module, ip, port, packet) do
    GenServer.cast(module, {:send, ip, port, packet})
  end

  @impl true
  def init({module, opts}) do
    local_port = Keyword.get(opts, :local_port, @default_local_port)
    {:ok, socket} = :gen_udp.open(local_port, [:binary, active: true])

    if Keyword.has_key?(opts, :remote_addr) do
      {remote_ip, remote_port} = Keyword.get(opts, :remote_addr)
      :ok = :gen_udp.connect(socket, remote_ip, remote_port)
    end

    {:ok, {module, socket}}
  end

  @impl true
  def handle_info({:udp, socket, ip, port, packet}, {module, state_socket})
      when socket == state_socket do
    module.recv(socket, ip, port, packet)
    {:noreply, {module, state_socket}}
  end

  @impl true
  def handle_cast({:send, packet}, {_, socket} = state) do
    :gen_udp.send(socket, packet)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send, ip, port, packet}, {_, socket} = state) do
    :gen_udp.send(socket, ip, port, packet)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, {_module, socket}) do
    :gen_udp.close(socket)
    :ok
  end
end
