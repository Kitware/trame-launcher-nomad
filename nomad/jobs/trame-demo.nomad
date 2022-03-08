job "trame-demo" {
  datacenters = ["dc1"]
  type = "batch"

  # User parameters (data directory, ...)
  parameterized {
    payload       = "forbidden"
    meta_required = ["SECRET"]
  }

  group "trame-demo" {

    network {
      port "http" {}
    }

    task "trame-demo" {

      # trame docker image app
      driver = "docker"
      config {
        image = "jourdain/trame-apps:demo"
        force_pull=true
        args = [
            "--port", "${NOMAD_PORT_http}",
            "--authKey", "${NOMAD_META_SECRET}",
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
        name = "trame-demo"
        tags = ["urlprefix-/${NOMAD_ALLOC_ID} strip=/${NOMAD_ALLOC_ID}"]
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
