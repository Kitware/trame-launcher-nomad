job "trame-launcher" {
  datacenters = ["dc1"]
  type = "service"

  group "trame-launcher" {

    network {
      port "http" {}
    }

    task "trame-launcher" {

      # trame docker image app
      driver = "docker"
      config {
        image = "jourdain/trame-apps:launcher"
        force_pull=true
        args = [
            "--port", "${NOMAD_PORT_http}",
        ]
        ports = ["http"]
      }

      # Required resources for job
      resources {
        cpu    = 100 # MHz
        memory = 50 # MB
      }

      # Consul registration + Fabio forwarding
      service {
        name = "trame-launcher"
        tags = ["urlprefix-/"]
        port = "http"

        check {
           name     = "alive"
           type     = "tcp"
           interval = "30s"
           timeout  = "10s"
         }
      }
    }
  }
}
