{ config, lib, options, pkgs, ... }:
let
  domain = "mydomain"; # todo change me
  graphana-secret-key = "#TODO";
in{
  config = {
    # services.prometheus.exporters.node = {
    #     enable = true;
    #     enabledCollectors = [
    #       "systemd"
    #     ];
    # };
    services.prometheus.exporters.graphite = {
      enable = true;
      openFirewall = true;
      mappingSettings = {
        mappings = [
          { # Network interfaces as label
            match = "scale\\.(.*)\\.net(_.*)?\\.(\\w+)\\.(\\w+)";
            match_type = "regex";
            name = "truenas_net\${2}_\${4}";
            labels = { hostname = "\${1}"; device = "\${3}"; };
          }
          # scale.<host>.cputemp.temperatures.cpu
          # scale.<host>.truenas_cpu_usage.cpu.cpu
          { # Cpu core as label
            match = "scale\\.(.*)\\.(\\w+)\\.(\\w+)\\.(cpu\\d?)";
            match_type = "regex";
            name = "truenas_\${2}_\${3}";
            labels = { hostname = "\${1}"; cpu = "\${4}"; };
          }
          { # All cores
            match = "scale\\.(.*)\\.(\\w+)\\.(\\w+)\\.cpu";
            match_type = "regex";
            name = "truenas_\${2}_\${3}";
            labels = { hostname = "\${1}"; cpu = "all"; };
          }
          { # Service name as label
            match = "scale\\.(.*)\\.services\\.(\\w+)\\.(.*)";
            match_type = "regex";
            name = "truenas_services_\${2}";
            labels = { hostname = "\${1}"; service = "\${3}"; };
          }
          { # Disk as label
            match = "scale\\.(.*)\\.truenas_disk_(\\w*)\\.(\\w*\\.)?(.*)\\.(\\w*)";
            match_type = "regex";
            name = "truenas_disk_\${2}_\${5}";
            labels = { hostname = "\${1}"; disk = "\${4}"; };
          }
          { # Cgroup as label
            match = "scale\\.(.*)\\.cgroup_(\\w+)\\.(\\w+)\\.(\\w+)";
            match_type = "regex";
            name = "truenas_cgroup_\${3}_\${4}";
            labels = { hostname = "\${1}"; cgroup = "\${2}"; };
          }
          { # Catchall
            match = "scale\\.(.*)\\.(\\w*)\\.(\\w*)\\.(\\w*)";
            match_type = "regex";
            name = "truenas_\${2}_\${3}_\${4}";
            labels = { hostname = "\${1}";};
          }
        ];
      };
    };

    services.prometheus = {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "${config.networking.hostName}";
          static_configs = [{
            targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
            labels = {host = "${config.networking.hostName}.${domain}.com";};
          }];
        }
        {
          job_name = "graphite";
          static_configs = [{
            targets = [ "localhost:${toString config.services.prometheus.exporters.graphite.port}" ];
            labels = {host = "truenas.${domain}.com";};
          }];
        }
      ];
      retentionTime = "5w";
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3001;
          enforce_domain = true;
          enable_gzip = true;
          domain = "${config.networking.hostName}.${domain}";
        };
        security.secret_key = "${graphana-secret-key}";
        # Prevents Grafana from phoning home
        analytics.reporting_enabled = false;
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
            isDefault = true;
            editable = false;
          }
        ];

      };
    };

    # services.nginx.virtualHosts."${config.networking.hostName}.${domain}" = {
    #   locations."/" = {
    #     proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
    #     proxyWebsockets = true;
    #     recommendedProxySettings = true;
    #   };
    # };
  };
}

