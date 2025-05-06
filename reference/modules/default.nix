{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../secrets/nixos
    ../users/youwen/nixos.nix
  ];

  # systemd.services.suntheme = {
  #   wantedBy = [ "default.target" ];
  #   after = [
  #     "network.target"
  #     "atd.service"
  #   ];
  #   wants = [ "atd.service" ];
  #   description = "Run suntheme to set daemons";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = "yes";
  #     ExecStart = ''${inputs.suntheme.packages.${pkgs.system}.default}/bin/suntheme'';
  #   };
  # };
  #
  # environment.systemPackages = [
  #   (pkgs.writeShellScriptBin "light.sh" ''
  #     /nix/var/nix/profiles/system/specialisation/dawn/bin/switch-to-configuration test
  #   '')
  #   (pkgs.writeShellScriptBin "dark.sh" ''
  #     /nix/var/nix/profiles/nix/system/bin/switch-to-configuration test
  #   '')
  # ];

  systemd.services = {
    colorscheme-dawn = {
      description = "Set system colorscheme to dawn";
      unitConfig = {
        ConditionPathExists = [
          "/etc/polarity"
          "/nix/var/nix/profiles/system/specialisation/dawn/bin/switch-to-configuration"
        ];
      };
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        PermissionsStartOnly = true;
        ExecStart = "/nix/var/nix/profiles/system/specialisation/dawn/bin/switch-to-configuration test";
      };
    };
    colorscheme-dusk = {
      description = "Set system colorscheme to dusk";
      unitConfig = {
        ConditionPathExists = [
          "/etc/polarity"
          "/nix/var/nix/profiles/system/bin/switch-to-configuration"
        ];
      };
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        PermissionsStartOnly = true;
        ExecStart = "/nix/var/nix/profiles/system/bin/switch-to-configuration test";
      };
    };
    refresh = let 
      flakeLocation = "/home/youwen/.config/liminalOS";
    in {
      description = "Automatically update liminalOS";
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      script = ''
        cd ${flakeLocation}
        ${pkgs.git}/bin/git config --global --add safe.directory ${flakeLocation}
        ${pkgs.git}/bin/git pull
      '';
      serviceConfig = {
        Environment = "HOME=/root";
      };
      wantedBy = [ ];
    };
  };
  systemd.timers = {
    colorscheme-dawn = {
      wantedBy = [ "timers.target" ];
      description = "Schedule system colorscheme change to dawn at 7 AM";
      timerConfig = {
        OnCalendar = "*-*-* 07:00:00";
        Persistent = true;
        Unit = "colorscheme-dawn.service";
      };
    };
    colorscheme-dusk = {
      wantedBy = [ "timers.target" ];
      description = "Schedule system colorscheme change to dusk at 6 PM";
      timerConfig = {
        OnCalendar = "*-*-* 18:00:00";
        Persistent = true;
        Unit = "colorscheme-dusk.service";
      };
    };
    refresh = {
      description = "Schedule daily system updates";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        Unit = "refresh.service";
      };
    };
  };

  security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units") {
            var unit = action.lookup("unit");

            if (unit == "colorscheme-dawn.service" || unit == "colorscheme-dusk.service") {
                if (subject.active && subject.local) {
                    return polkit.Result.YES;
                } else {
                    return polkit.Result.AUTH_ADMIN_KEEP;
                }
            }
        }
        return polkit.Result.NOT_HANDLED;
    });
  '';

  nix.extraOptions = ''
    !include ${config.age.secrets.nix_config_github_pat.path}
  '';

  nix.settings.trusted-users = [ "youwen" ];

  liminalOS.theming = {
    # wallpaper = "${inputs.wallpapers}/aesthetic/afterglow_city_skyline_at_night.png";
    # wallpaper = "${
    #   pkgs.fetchFromGitHub {
    #     owner = "dharmx";
    #     repo = "walls";
    #     rev = "6bf4d733ebf2b484a37c17d742eb47e5139e6a14";
    #     hash = "sha256-YdPkJ+Bm0wq/9LpuST6s3Aj13ef670cQOxAEIhJg26E=";
    #     sparseCheckout = [ "radium" ];
    #   }
    # }/radium/a_mountain_range_at_night.png";

    wallpaper = lib.mkDefault (
      pkgs.fetchurl {
        # url = "https://code.youwen.dev/youwen5/wallpapers/raw/branch/main/anime-with-people/eternal-blue.jpg";
        # url = "https://w.wallhaven.cc/full/rr/wallhaven-rrv23j.jpg";
        # hash = "sha256-PCyWyFgMxVYgDjPMtFbQoMTzN61zdUtiP6Lmgc3dRfk=";
        # hash = "sha256-PcE9TR82IupRl/zqAZ028GMuARAk2CQaU0XUNfw4gkI=";
        url = "https://i.imgur.com/jlKXCA3.jpeg";
        hash = "sha256-yJGYLqBLScJkUSbre8Ve3dWEj49f1RYNS/bnfXzRzbU=";
      }
    );

    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/oxocarbon-dark.yaml";
    polarity = lib.mkDefault "dark";
  };

  environment.etc.polarity.text = lib.mkDefault "dusk";

  specialisation = {
    dawn.configuration = {
      environment.etc."specialisation".text = "dawn";
      environment.etc.polarity.text = "dawn";
      liminalOS.theming = {
        wallpaper = pkgs.fetchurl {
          # url = "https://code.youwen.dev/youwen5/wallpapers/raw/branch/main/aesthetic/afterglow_city_skyline_at_night.png";
          # hash = "sha256-fYMzoY3un4qGOSR4DMqVUAFmGGil+wUze31rLLrjcAc=";
          url = "https://i.redd.it/ouo0vm6gn9f91.png";
          hash = "sha256-5t8HyqZhOw9Zy2LYWhLurBDWi+1KYjsPzU+6RsTaGqk=";
        };
        base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-dawn.yaml";
        # base16Scheme = null;
        polarity = "light";
      };
    };
  };
}
