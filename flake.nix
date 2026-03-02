{
  description = "OSGEO-Inject - Lightweight affiliate badge system for OSGeo projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Pre-commit hooks configuration
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # JavaScript/CSS linting and formatting
            eslint = {
              enable = true;
              entry = "${pkgs.nodePackages.eslint}/bin/eslint --fix";
              files = "\\.js$";
            };
            prettier = {
              enable = true;
              entry = "${pkgs.nodePackages.prettier}/bin/prettier --write";
              files = "\\.(js|css|json|md|yml|yaml)$";
            };

            # Nginx configuration validation
            nginx-lint = {
              enable = true;
              entry = "${pkgs.writeShellScript "nginx-lint" ''
                ${pkgs.nginx}/bin/nginx -t -c $1 -p $(dirname $1) 2>&1 || exit 1
              ''}";
              files = "nginx\\.conf$";
              pass_filenames = true;
            };

            # License compliance (REUSE)
            reuse = {
              enable = true;
              entry = "${pkgs.reuse}/bin/reuse lint";
              pass_filenames = false;
            };

            # Spell checking
            typos = {
              enable = true;
            };

            # YAML validation
            yamllint = {
              enable = true;
            };

            # JSON validation
            check-json = {
              enable = true;
            };

            # Trailing whitespace
            trim-trailing-whitespace = {
              enable = true;
            };

            # End of file fixer
            end-of-file-fixer = {
              enable = true;
            };

            # Check for merge conflicts
            check-merge-conflict = {
              enable = true;
              entry = "${pkgs.git}/bin/git diff --check";
            };

            # Detect secrets
            detect-secrets = {
              enable = true;
              entry = "${pkgs.detect-secrets}/bin/detect-secrets-hook --baseline .secrets.baseline";
              pass_filenames = true;
            };

            # Shell script checks
            shellcheck = {
              enable = true;
            };

            # Nix formatting
            nixpkgs-fmt = {
              enable = true;
            };
          };
        };

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          inherit (pre-commit-check) shellHook;

          buildInputs = with pkgs; [
            # JavaScript tooling
            nodejs_20
            nodePackages.npm
            nodePackages.eslint
            nodePackages.prettier
            nodePackages.typescript

            # Nginx
            nginx

            # Documentation
            python312
            python312Packages.mkdocs
            python312Packages.mkdocs-material
            python312Packages.mkdocs-mermaid2-plugin
            python312Packages.pygments

            # License compliance
            reuse

            # Shell scripting
            gum
            shellcheck
            shfmt

            # Utilities
            jq
            yq-go
            curl
            httpie

            # Spell checking
            typos

            # Secrets detection
            detect-secrets

            # Git
            git
            gh

            # Nix tooling
            nixpkgs-fmt
            nil

            # Image optimization
            optipng
            jpegoptim

            # Testing
            chromium

            # Deployment
            nixos-anywhere

            # Database (for Matomo backups)
            mariadb
          ];

          OSGEO_INJECT_DOMAIN = "affiliate.osgeo.org";
        };

        # Packages
        packages = {
          # Build the static assets
          static = pkgs.stdenv.mkDerivation {
            pname = "osgeo-inject-static";
            version = "0.1.0";
            src = ./src;

            buildInputs = [ pkgs.nodePackages.uglify-js pkgs.clean-css-cli ];

            buildPhase = ''
              # Minify JavaScript
              ${pkgs.nodePackages.uglify-js}/bin/uglifyjs js/osgeo-inject.js \
                --compress --mangle -o js/osgeo-inject.min.js

              # Minify CSS
              ${pkgs.nodePackages.clean-css-cli}/bin/cleancss \
                -o css/osgeo-inject.min.css css/osgeo-inject.css
            '';

            installPhase = ''
              mkdir -p $out
              cp -r . $out/
            '';
          };

          # Build documentation
          docs = pkgs.stdenv.mkDerivation {
            pname = "osgeo-inject-docs";
            version = "0.1.0";
            src = ./.;

            buildInputs = with pkgs; [
              python312
              python312Packages.mkdocs
              python312Packages.mkdocs-material
              python312Packages.mkdocs-mermaid2-plugin
            ];

            buildPhase = ''
              mkdocs build -d site
            '';

            installPhase = ''
              mv site $out
            '';
          };

          default = self.packages.${system}.static;
        };

        # Apps for common tasks
        apps = {
          # Serve documentation locally
          docs-serve = {
            type = "app";
            program = toString (pkgs.writeShellScript "docs-serve" ''
              cd ${self}
              ${pkgs.python312Packages.mkdocs}/bin/mkdocs serve
            '');
          };

          # Build documentation
          docs-build = {
            type = "app";
            program = toString (pkgs.writeShellScript "docs-build" ''
              cd ${self}
              ${pkgs.python312Packages.mkdocs}/bin/mkdocs build
            '');
          };

          # Run test server
          test-server = {
            type = "app";
            program = toString (pkgs.writeShellScript "test-server" ''
              cd ${self}/src
              ${pkgs.python312}/bin/python -m http.server 8080
            '');
          };

          # Onboard a new site
          onboard = {
            type = "app";
            program = toString (pkgs.writeShellScript "onboard" ''
              ${self}/scripts/onboard-site.sh "$@"
            '');
          };

          # Update announcement
          announce = {
            type = "app";
            program = toString (pkgs.writeShellScript "announce" ''
              ${self}/scripts/update-announcement.sh "$@"
            '');
          };

          # Backup Matomo
          backup = {
            type = "app";
            program = toString (pkgs.writeShellScript "backup" ''
              ${self}/scripts/backup.sh "$@"
            '');
          };

          # Restore Matomo
          restore = {
            type = "app";
            program = toString (pkgs.writeShellScript "restore" ''
              ${self}/scripts/restore.sh "$@"
            '');
          };

          default = self.apps.${system}.test-server;
        };

        # Checks
        checks = {
          pre-commit-check = pre-commit-check;
        };
      }
    ) // {
      # NixOS modules for deployment
      nixosModules = {
        osgeo-inject = import ./nixos/module.nix;
        default = self.nixosModules.osgeo-inject;
      };

      # NixOS configurations for VM testbed
      nixosConfigurations = {
        osgeo-inject-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./nixos/vm-configuration.nix
            self.nixosModules.osgeo-inject
          ];
        };
      };
    };
}
