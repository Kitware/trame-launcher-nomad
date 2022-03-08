job "trame-launcher" {
  datacenters = ["dc1"]
  type = "service"

  group "trame-launcher" {

    network {
      port "http" {}
    }

    task "trame-launcher" {

        # NOMAD_ADDR=http://127.0.0.1:4646
        # NOMAD_NAMESPACE=default
        # NOMAD_TOKEN=xxxx-xxxx-xxxx-xxxx
        # NOMAD_REGION=us-east-1a
        # NOMAD_CLIENT_CERT=/path/to/tls/client.crt
        # NOMAD_CLIENT_KEY=/path/to/tls/client.key
        env {
            NOMAD_ADDR = "http://${attr.unique.hostname}:4646"
        }

      # trame docker image app
      driver = "docker"
      config {
        image = "kitware/trame:launcher"
        force_pull=true
        args = [
            "--port", "${NOMAD_PORT_http}",
            "--redirect", "http://${attr.unique.hostname}:9999",
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
