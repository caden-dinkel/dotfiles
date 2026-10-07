{ pkgs, ... }:
{
  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    port = 55555;
    bindAddress = "127.0.0.1";
    secretKeyFile = config.sops.secrets."bin-cache-key".path;
  };
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    # recommendedTlsSettings = true;
    virtualHosts."binary-cache" = {
      # enableACME = true;
      # forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:55555";
      };
    };
  };

  /*
    security.acme = {
      acceptTerms = true;
      defaults.email = "example@cache.com";
    };
  */

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
