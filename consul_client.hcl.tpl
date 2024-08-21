datacenter = "dc1"
data_dir = "/opt/consul"
performance {raft_multiplier = 1}
retry_join = ["SERVER_IP"]
client_addr = "CLIENT_IP"
bind_addr = "{{ GetInterfaceIP \"enp1s0\" }}"
log_level = "TRACE"
enable_syslog = true
