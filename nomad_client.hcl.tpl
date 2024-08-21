data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}

client {
  
  enabled       = true
  network_speed = 10
  servers = ["SERVER_IP:4647"]
  
  options {
    "docker.privileged.enabled" = "true"
    "driver.raw_exec.enable" = "1"
  }
  
  host_volume "datavol" {
    read_only = false
    path = "/data/nomad/datavol"
  }
}

consul {
  address = "CLIENT_IP:8500"
}
