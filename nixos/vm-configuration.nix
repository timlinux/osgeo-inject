# SPDX-FileCopyrightText: 2026 Tim Sketcher <tim@kartoza.com>
# SPDX-License-Identifier: MIT

# NixOS VM configuration for OSGEO-Inject testbed
{ config, pkgs, lib, ... }:

{
  imports = [
    ./module.nix
  ];

  # VM-specific settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking = {
    hostName = "osgeo-inject-vm";
    useDHCP = true;

    # Add local hosts entries for testing
    extraHosts = ''
      127.0.0.1 affiliate.osgeo.org
      127.0.0.1 matomo.affiliate.osgeo.org
      127.0.0.1 test.osgeo.org
    '';
  };

  # Enable OSGEO-Inject service
  services.osgeo-inject = {
    enable = true;
    domain = "affiliate.osgeo.org";
    matomoDomain = "matomo.affiliate.osgeo.org";
    enableMatomo = true;

    # Disable ACME for local testing (use self-signed)
    enableACME = false;

    # Add test origins
    corsOrigins = [
      "*.osgeo.org"
      "*.qgis.org"
      "test.osgeo.org"
      "localhost"
    ];
  };

  # Self-signed certificates for testing
  security.pki.certificateFiles = [
    (pkgs.runCommand "self-signed-cert" {
      buildInputs = [ pkgs.openssl ];
    } ''
      mkdir -p $out
      openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout $out/key.pem \
        -out $out/cert.pem \
        -subj "/CN=affiliate.osgeo.org" \
        -addext "subjectAltName=DNS:affiliate.osgeo.org,DNS:matomo.affiliate.osgeo.org,DNS:test.osgeo.org"
    '' + "/cert.pem")
  ];

  # Nginx with self-signed certs for testing
  services.nginx.virtualHosts = {
    "affiliate.osgeo.org" = {
      sslCertificate = "/etc/ssl/test-cert.pem";
      sslCertificateKey = "/etc/ssl/test-key.pem";
    };
    "matomo.affiliate.osgeo.org" = {
      sslCertificate = "/etc/ssl/test-cert.pem";
      sslCertificateKey = "/etc/ssl/test-key.pem";
    };
  };

  # Generate test certificates on boot
  systemd.services.generate-test-certs = {
    description = "Generate test SSL certificates";
    wantedBy = [ "multi-user.target" ];
    before = [ "nginx.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f /etc/ssl/test-cert.pem ]; then
        ${pkgs.openssl}/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
          -keyout /etc/ssl/test-key.pem \
          -out /etc/ssl/test-cert.pem \
          -subj "/CN=affiliate.osgeo.org" \
          -addext "subjectAltName=DNS:affiliate.osgeo.org,DNS:matomo.affiliate.osgeo.org,DNS:test.osgeo.org"
        chmod 644 /etc/ssl/test-cert.pem
        chmod 600 /etc/ssl/test-key.pem
      fi
    '';
  };

  # Deploy test content
  systemd.services.deploy-test-content = {
    description = "Deploy OSGEO-Inject test content";
    wantedBy = [ "multi-user.target" ];
    after = [ "nginx.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Create directories
      mkdir -p /var/www/osgeo-inject/{js,css,images,content}

      # Copy static files (these would normally be built from source)
      cat > /var/www/osgeo-inject/index.html << 'EOF'
      <!DOCTYPE html>
      <html>
      <head><title>OSGEO-Inject Test Server</title></head>
      <body>
        <h1>OSGEO-Inject Test Server</h1>
        <p>Server is running. Visit <a href="/demo">/demo</a> for the test page.</p>
      </body>
      </html>
      EOF

      # Set permissions
      chown -R nginx:nginx /var/www/osgeo-inject
    '';
  };

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Users
  users.users.root.initialPassword = "nixos";

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "nginx" ];
    initialPassword = "admin";
  };

  # Useful packages for testing
  environment.systemPackages = with pkgs; [
    vim
    curl
    htop
    jq
    gum
    git
  ];

  # MariaDB for Matomo
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "matomo" ];
    ensureUsers = [
      {
        name = "matomo";
        ensurePermissions = {
          "matomo.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # Disable power management
  powerManagement.enable = false;

  # VM-specific optimizations
  virtualisation = {
    memorySize = 2048;
    cores = 2;
    diskSize = 8192;

    # Forward ports for external access
    forwardPorts = [
      { from = "host"; host.port = 8080; guest.port = 80; }
      { from = "host"; host.port = 8443; guest.port = 443; }
      { from = "host"; host.port = 2222; guest.port = 22; }
    ];

    # Share project directory
    sharedDirectories = {
      project = {
        source = "/home/timlinux/dev/js/OSGEO-Inject";
        target = "/project";
      };
    };
  };

  # System state version
  system.stateVersion = "24.05";
}
