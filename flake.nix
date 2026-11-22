{
  description = "altf4's NixOS + Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      disko,
      sops-nix,
      nix-darwin,
      ...
    }:
    let
      homeManagerFor = name: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.users.altf4 = import ./hosts/${name}/home.nix;
      };
      mkNixos =
        name:
        nixpkgs.lib.nixosSystem {
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            (homeManagerFor name)
            ./hosts/${name}/configuration.nix
          ];
        };
      mkDarwin =
        name:
        nix-darwin.lib.darwinSystem {
          modules = [
            sops-nix.darwinModules.sops
            home-manager.darwinModules.home-manager
            (homeManagerFor name)
            ./hosts/${name}/configuration.nix
          ];
        };
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    in
    {
      nixosConfigurations.saturn = mkNixos "saturn";
      darwinConfigurations.mercury = mkDarwin "mercury";

      checks = nixpkgs.lib.foldlAttrs (
        acc: name: host:
        nixpkgs.lib.recursiveUpdate acc {
          ${host.config.nixpkgs.hostPlatform.system}.${name} = host.config.system.build.toplevel;
        }
      ) { } (self.nixosConfigurations // self.darwinConfigurations);

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
