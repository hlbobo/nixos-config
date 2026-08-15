# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, lib, dms, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    
    # detect Winslop 11
    useOSProber = true;
   
    theme = ./grub-theme;
    gfxmodeEfi = "1920x1080";
    gfxpayloadEfi = "keep";
  };

  boot.loader.efi.canTouchEfiVariables = true;

  # Host Platform
  nixpkgs.hostPlatform = "x86_64-linux";

  # Use latest kernel.
  # boot.kernelPackages = pkgs.linuxPackages_latest; # vanilla kernel
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest; # Xanmod patch kernel

  networking.hostName = "bobo"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];  

  # script for github update
  programs.bash.interactiveShellInit = ''
  nixsync() {
      if [ -z "$1" ]; then
        echo "Usage: nixsync \"commit message\""
        return 1
      fi
      cd /etc/nixos || return 1
      git add -A
      git commit -m "$1"
      git push
    }
  ''; 

  # For flatpak
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/flatpak - - - - ${pkgs.flatpak}/bin/flatpak"
  ];
  
  # enable battery limiter
  hardware.asus.battery = {
    chargeUpto = 60;   # Maximum level of charge for your battery, as a percentage.
    enableChargeUptoScript = true; # Whether to add charge-upto to environment.systemPackages. `charge-upto 85` temporarily sets the charge limit to 85%.
  };
 
  # Enable OpenGL
  hardware.graphics = {
     enable = true;
     enable32Bit = true;
  };

  # Enable NVIDIA Drivers and Optimus-Prime
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;

    prime = {
      offload = {
	enable = true;
	enableOffloadCmd = true;
      };

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  specialisation = {
    trve-gamer.configuration = {
       hardware.nvidia = {
         prime.sync.enable = lib.mkForce true;
	 prime.offload = {
	   enable = lib.mkForce false;
	   enableOffloadCmd = lib.mkForce false;
	 };
       };
    };
  };
  
  # Niri Vram fix
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text = builtins.toJSON {
    rules = [
      {
        pattern = {
          feature = "procname";
          matches = "niri";
        };
        profile = "Limit Free Buffer Pool On Wayland Compositors";
      }
    ];
    profiles = [
      {
        name = "Limit Free Buffer Pool On Wayland Compositors";
        settings = [
          {
            key = "GLVidHeapReuseRatio";
            value = 0;
          }
        ];
      }
    ];
  };

  services.lact.enable = true;


  ########################
  ##  NIRI + DMS SETUP  ##
  ########################

  programs.niri.enable = true;
  services.displayManager.defaultSession = lib.mkForce "niri";
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users."bobo" = { pkgs, ... }: {
      imports = [
        dms.homeModules.dank-material-shell
      ];

      programs.dank-material-shell = {
        enable = true;
      };
      
      programs.bash = {
        enable = true;
        shellAliases = {
          rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#bobo";
          nixconfig = "sudo nano /etc/nixos/configuration.nix";
          nixflake = "sudo nano /etc/nixos/flake.nix";
          niriconfig = "sudo nano ~/.config/niri/config.kdl";
          niribinds = "sudo nano ~/.config/niri/dms/binds.kdl";
        };
      };

      home.stateVersion = "26.05";
    };
  };

  #services.displayManager.dms-greeter = {
   # enable = true;
   # compositor.name = "niri";
   # configHome = "/home/bobo";
   # package = dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  #};

  # Set your time zone.
  time.timeZone = "Europe/Bucharest";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ro_RO.UTF-8";
    LC_IDENTIFICATION = "ro_RO.UTF-8";
    LC_MEASUREMENT = "ro_RO.UTF-8";
    LC_MONETARY = "ro_RO.UTF-8";
    LC_NAME = "ro_RO.UTF-8";
    LC_NUMERIC = "ro_RO.UTF-8";
    LC_PAPER = "ro_RO.UTF-8";
    LC_TELEPHONE = "ro_RO.UTF-8";
    LC_TIME = "ro_RO.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."bobo" = {
    isNormalUser = true;
    description = "bobo";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  services.hardware.openrgb.enable = true;

 ################
 ##  PROGRAMS  ##
 ################

  # emoji fonts
  fonts.packages = with pkgs; [
    noto-fonts-color-emoji
  ];
  
  # Install Steam
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];
  programs.steam = {
    enable = true;
    package = pkgs.millennium-steam;
  };
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
  
  # Install firefox.
  # programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # install KDE Connect
  programs.kdeconnect.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     vim
     wget
     pciutils
     fastfetch
     mangohud
     winetricks
     wine-staging
     protonplus
     lutris
     heroic
     obs-studio
     vlc
     prismlauncher
     bottles
     (discord.override { withVencord = true; })
     gimp
     openrgb
     libreoffice
     kdePackages.kdenlive
     qbittorrent
     tailscale
     librewolf
     vscodium
     git
     gh
     alacritty
     fuzzel
     nvtopPackages.full
     lact
     xwayland-satellite
     yad
     jq
     
     # media codecs
     gst_all_1.gstreamer
     gst_all_1.gst-plugins-base
     gst_all_1.gst-plugins-good
     gst_all_1.gst-plugins-bad
     gst_all_1.gst-plugins-ugly
     gst_all_1.gst-libav        # ffmpeg-backed codecs (h264, aac, etc.)

     ffmpeg-full                # full ffmpeg with all codecs enabled

     libdvdcss                  # DVD decryption, like Nobara includes
     libdvdread
     libdvdnav
     nvidia-vaapi-driver
  ];

  environment.sessionVariables.LIBVA_DRIVER_NAME = "nvidia";

  services = {
    asusd = {
      enable = true;
      #  enableUserService = true;
    };
    flatpak = {
      enable = true;
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
