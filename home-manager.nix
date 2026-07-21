{
  lib,
  config,
  ...
}:

let
  cfg = config.services.ag2r;
in
{
  meta.maintainers = with lib.maintainers; [ ];

  options.services.ag2r = {
    enable = lib.mkEnableOption "AG2R — Antigravity 2.0 Remote";

    package = lib.mkOption {
      type = lib.types.package;
      description = ''
        The ag2r package to use. Must be provided by the user
        (e.g. from a flake input or overlay), since ag2r is not
        part of nixpkgs.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "HTTP server listen port";
    };

    cdpHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Chrome DevTools Protocol host";
    };

    cdpPort = lib.mkOption {
      type = lib.types.port;
      default = 9000;
      description = "Chrome DevTools Protocol port";
    };

    pollIntervalMs = lib.mkOption {
      type = lib.types.int;
      default = 500;
      description = "Antigravity DOM polling interval in milliseconds";
    };

    auth = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable password-based authentication";
      };
      password = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Password required to log into the web UI";
      };
      sessionSecret = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Session signing secret (`openssl rand -hex 32`)";
      };
    };

    tunnel = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Cloudflare tunnel mode";
      };
      url = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "https://ag2r.yourdomain.com";
        description = "Public URL for push notification links";
      };
    };

    ag2rEnv = lib.mkOption {
      type = lib.types.enum [
        "production"
        "development"
        "staging"
      ];
      default = "production";
      description = ''
        Environment name. Controls PWA identity (name/icon) and config directory
        namespace (~/.config/ag2r/ vs ~/.config/ag2r-{env}/).
      '';
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable verbose debug logging (AG2R_DEBUG=1)";
    };

    telemetry = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable anonymous usage telemetry (sent to developer's Firebase project)";
    };

    vapidEmail = lib.mkOption {
      type = lib.types.str;
      default = "mailto:ag2r@omercanyy.com";
      description = "Contact email for VAPID push notification identity";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Ensure config directory exists before the service starts
    home.activation.ag2rConfigDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config/ag2r"
    '';

    systemd.user.services.ag2r = {
      Unit = {
        Description = "AG2R — Antigravity 2.0 Remote";
        Documentation = "https://github.com/the-future-company/ag2r";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "on-failure";
        RestartSec = "5";

        Environment = [
          "PORT=${toString cfg.port}"
          "CDP_HOST=${cfg.cdpHost}"
          "CDP_PORT=${toString cfg.cdpPort}"
          "POLL_INTERVAL_MS=${toString cfg.pollIntervalMs}"
          "AG2R_ENV=${cfg.ag2rEnv}"
          "VAPID_EMAIL=${cfg.vapidEmail}"
        ]
        # Auth
        ++ lib.optional cfg.auth.enable "AUTH_ENABLED=true"
        ++ lib.optional (cfg.auth.enable && cfg.auth.password != "") "APP_PASSWORD=${cfg.auth.password}"
        ++ lib.optional (
          cfg.auth.enable && cfg.auth.sessionSecret != ""
        ) "SESSION_SECRET=${cfg.auth.sessionSecret}"
        # Tunnel
        ++ lib.optional cfg.tunnel.enable "TUNNEL_ENABLED=true"
        ++ lib.optional (cfg.tunnel.url != "") "TUNNEL_URL=${cfg.tunnel.url}"
        # Debug / telemetry
        ++ lib.optional cfg.debug "AG2R_DEBUG=1"
        ++ lib.optional (!cfg.telemetry) "AG2R_TELEMETRY=false";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
