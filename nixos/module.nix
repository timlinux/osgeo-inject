# SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
# SPDX-License-Identifier: MIT

# NixOS module for OSGEO-Inject
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.osgeo-inject;
in
{
  options.services.osgeo-inject = {
    enable = mkEnableOption "OSGEO-Inject affiliate badge server";

    domain = mkOption {
      type = types.str;
      default = "affiliate.osgeo.org";
      description = "Domain name for the OSGEO-Inject server";
    };

    matomoDomain = mkOption {
      type = types.str;
      default = "matomo.affiliate.osgeo.org";
      description = "Domain name for the Matomo analytics server";
    };

    enableMatomo = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Matomo analytics";
    };

    enableACME = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use Let's Encrypt for SSL certificates";
    };

    acmeEmail = mkOption {
      type = types.str;
      default = "";
      description = "Email for Let's Encrypt notifications";
    };

    staticDir = mkOption {
      type = types.path;
      default = "/var/www/osgeo-inject";
      description = "Directory containing static files";
    };

    corsOrigins = mkOption {
      type = types.listOf types.str;
      default = [
        "*.osgeo.org"
        "*.qgis.org"
        "*.gdal.org"
        "*.geoserver.org"
        "*.postgis.net"
        "*.openlayers.org"
        "*.mapserver.org"
        "*.geonode.org"
        "*.pgrouting.org"
        "*.leafletjs.com"
      ];
      description = "List of allowed CORS origins (supports wildcards)";
    };

    matomoDbPassword = mkOption {
      type = types.str;
      default = "";
      description = "Matomo database password";
    };

    backupDir = mkOption {
      type = types.path;
      default = "/var/backups/osgeo-inject";
      description = "Directory for backups";
    };

    enableBackups = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable automated backups";
    };

    backupSchedule = mkOption {
      type = types.str;
      default = "daily";
      description = "Backup schedule (systemd calendar format or 'daily'/'weekly')";
    };
  };

  config = mkIf cfg.enable {
    # Required packages
    environment.systemPackages = with pkgs; [
      nginx
      gzip
      rsync
    ];

    # Create directories
    systemd.tmpfiles.rules = [
      "d ${cfg.staticDir} 0755 nginx nginx -"
      "d ${cfg.staticDir}/js 0755 nginx nginx -"
      "d ${cfg.staticDir}/css 0755 nginx nginx -"
      "d ${cfg.staticDir}/images 0755 nginx nginx -"
      "d ${cfg.staticDir}/content 0755 nginx nginx -"
      "d ${cfg.backupDir} 0750 root root -"
    ];

    # Nginx configuration
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      # CORS map configuration
      appendConfig = ''
        map $http_origin $cors_origin {
            default "";
            ${concatMapStrings (origin:
              let
                escaped = replaceStrings ["." "*"] ["\\." ".*"] origin;
              in
              "\"~^https?://${escaped}$\" $http_origin;\n            "
            ) cfg.corsOrigins}
            "~^https?://localhost(:[0-9]+)?$" $http_origin;
            "~^https?://127\\.0\\.0\\.1(:[0-9]+)?$" $http_origin;
        }
      '';

      virtualHosts = {
        ${cfg.domain} = {
          forceSSL = cfg.enableACME;
          enableACME = cfg.enableACME;

          root = cfg.staticDir;

          locations = {
            "/" = {
              index = "index.html";
              tryFiles = "$uri $uri/ =404";
            };

            "/js/" = {
              extraConfig = ''
                add_header Access-Control-Allow-Origin $cors_origin always;
                add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
                add_header Access-Control-Max-Age 86400 always;
                add_header Cache-Control "public, max-age=3600, must-revalidate" always;

                if ($request_method = 'OPTIONS') {
                    add_header Access-Control-Allow-Origin $cors_origin;
                    add_header Access-Control-Allow-Methods "GET, OPTIONS";
                    add_header Access-Control-Max-Age 86400;
                    add_header Content-Length 0;
                    add_header Content-Type text/plain;
                    return 204;
                }
              '';
            };

            "/css/" = {
              extraConfig = ''
                add_header Access-Control-Allow-Origin $cors_origin always;
                add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
                add_header Access-Control-Max-Age 86400 always;
                add_header Cache-Control "public, max-age=3600, must-revalidate" always;

                if ($request_method = 'OPTIONS') {
                    add_header Access-Control-Allow-Origin $cors_origin;
                    add_header Access-Control-Allow-Methods "GET, OPTIONS";
                    add_header Access-Control-Max-Age 86400;
                    add_header Content-Length 0;
                    add_header Content-Type text/plain;
                    return 204;
                }
              '';
            };

            "/images/" = {
              extraConfig = ''
                add_header Access-Control-Allow-Origin $cors_origin always;
                add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
                add_header Access-Control-Max-Age 86400 always;
                add_header Cache-Control "public, max-age=604800, immutable" always;

                if ($request_method = 'OPTIONS') {
                    add_header Access-Control-Allow-Origin $cors_origin;
                    add_header Access-Control-Allow-Methods "GET, OPTIONS";
                    add_header Access-Control-Max-Age 86400;
                    add_header Content-Length 0;
                    add_header Content-Type text/plain;
                    return 204;
                }
              '';
            };

            "/content/" = {
              extraConfig = ''
                add_header Access-Control-Allow-Origin $cors_origin always;
                add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
                add_header Access-Control-Max-Age 86400 always;
                add_header Cache-Control "public, max-age=900, must-revalidate" always;

                if ($request_method = 'OPTIONS') {
                    add_header Access-Control-Allow-Origin $cors_origin;
                    add_header Access-Control-Allow-Methods "GET, OPTIONS";
                    add_header Access-Control-Max-Age 86400;
                    add_header Content-Length 0;
                    add_header Content-Type text/plain;
                    return 204;
                }
              '';
            };

            "/health" = {
              extraConfig = ''
                access_log off;
                return 200 'OK';
                add_header Content-Type text/plain;
              '';
            };
          };

          extraConfig = ''
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-XSS-Protection "1; mode=block" always;
            add_header Referrer-Policy "strict-origin-when-cross-origin" always;
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
          '';
        };
      };
    };

    # Matomo configuration
    services.matomo = mkIf cfg.enableMatomo {
      enable = true;
      hostname = cfg.matomoDomain;
      nginx = {
        forceSSL = cfg.enableACME;
        enableACME = cfg.enableACME;
      };
    };

    # ACME configuration
    security.acme = mkIf cfg.enableACME {
      acceptTerms = true;
      defaults.email = cfg.acmeEmail;
    };

    # Backup service
    systemd.services.osgeo-inject-backup = mkIf cfg.enableBackups {
      description = "OSGEO-Inject backup service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "backup-osgeo-inject" ''
          #!/usr/bin/env bash
          set -euo pipefail

          TIMESTAMP=$(date +%Y%m%d_%H%M%S)
          BACKUP_FILE="${cfg.backupDir}/osgeo-inject_$TIMESTAMP.tar.gz"

          # Backup static files
          tar -czf "$BACKUP_FILE" -C ${cfg.staticDir} .

          # Backup Matomo database if enabled
          ${optionalString cfg.enableMatomo ''
            ${pkgs.mariadb}/bin/mysqldump matomo | gzip >> "${cfg.backupDir}/matomo_$TIMESTAMP.sql.gz"
          ''}

          # Generate checksum
          sha256sum "$BACKUP_FILE" >> "${cfg.backupDir}/checksums.txt"

          # Clean old backups (keep last 30 days)
          find ${cfg.backupDir} -name "*.tar.gz" -mtime +30 -delete
          find ${cfg.backupDir} -name "*.sql.gz" -mtime +30 -delete
        '';
      };
    };

    systemd.timers.osgeo-inject-backup = mkIf cfg.enableBackups {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.backupSchedule;
        Persistent = true;
      };
    };

    # Firewall rules
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
