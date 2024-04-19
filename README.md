# DNS AdBlocker

**TODO: Add description**

## Running

Run the program with root privileges (required for opening the socket):
```bash
sudo mix run
```

Configure the machine to be the default network's DNS server.

## Configuration

Create a `config/runtime.exs` file with the following content:
```elixir
import Config
config :dns_adblocker, :remote_dns_addr, "<REMOTE_DNS_IP>:<REMOTE_DNS_PORT>"
```

Replace `<REMOTE_DNS_IP>` and `<REMOTE_DNS_PORT>` with the IP and port of the actual DNS server.

