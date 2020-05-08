job "grafana" {
  datacenters = ["dc1"]

  group "grafana" {
    count = 1

    volume "grafana" {
      type   = "host"
      source = "grafana"
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:6.7.3"

        port_map {
          grafana_ui = 3000
        }

        volumes = [
          "local/datasources:/etc/grafana/provisioning/datasources",
          "local/dashboards:/etc/grafana/provisioning/dashboards",
          "local/dashboards/src:/var/lib/grafana/dashboards",
        ]
      }

      env {
        GF_AUTH_ANONYMOUS_ENABLED  = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE = "Editor"
      }

      template {
        data = <<EOH
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  url: http://{{ range $i, $s := service "prometheus" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}
  isDefault: true
  version: 1
  editable: false
EOH

        destination = "local/datasources/prometheus.yaml"
      }

      template {
        data = <<EOH
apiVersion: 1

providers:
- name: Nomad Autoscaler
  folder: Nomad
  folderUid: nomad
  type: file
  disableDeletion: true
  editable: false
  allowUiUpdates: false
  options:
    path: /var/lib/grafana/dashboards
EOH

        destination = "local/dashboards/nomad-autoscaler.yaml"
      }

      artifact {
        source      = "https://gist.githubusercontent.com/lgfa29/229af0e06c04f28316a1a23e67718a78/raw/ac1f4261e1c4629125271391eccdca6e9d7af3d1/dashboard.json"
        destination = "local/dashboards/src/nomad-autoscaler.json"
        mode        = "file"
      }

      volume_mount {
        volume      = "grafana"
        destination = "/var/lib/grafana"
      }

      resources {
        cpu    = 100
        memory = 64

        network {
          mbits = 10

          port "grafana_ui" {
            static = 3000
          }
        }
      }
    }
  }
}