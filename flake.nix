{
  description = "NixOS configuration with flakes";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    millennium = {
      url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, dms, home-manager, millennium,... }@inputs: {
    # replace <your-hostname> with your actual hostname
    nixosConfigurations.bobo = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit dms inputs; };
      modules = [
	dms.nixosModules.dank-material-shell
        home-manager.nixosModules.home-manager
        nixos-hardware.nixosModules.asus-fx506hm
        ./hardware-configuration.nix
	./configuration.nix
      ];
    };
  };
}
