datacenter = "dc1"
data_dir = "/opt/consul"
performance {raft_multiplier = 1}
retry_join = ["CONSUL_SERVER_IP"]
client_addr = "CONSUL_CLIENT_IP"
bind_addr = "{{ GetInterfaceIP \"enp1s0\" }}"
log_level = "TRACE"
enable_syslog = true
