enable_syslog = true
log_level = "debug"
bind_addr = "0.0.0.0"    
datacenter = "dc1"    
# Setup data dir
data_dir = "/opt/nomad/server"    
advertise {
  rpc = "NOMAD_SERVER_IP:4647"
}    
server {
  enabled = true
  bootstrap_expect = 1
	rejoin_after_leave = true
}
