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
  };

  outputs = { self, nixpkgs, home-manager, disko, sops-nix, ... }:
    let
      homeManagerFor = homeFile: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.altf4 = import homeFile;
      };
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ];
    in
    {
      nixosConfigurations.saturn = nixpkgs.lib.nixosSystem {
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/saturn/configuration.nix
          home-manager.nixosModules.home-manager
          (homeManagerFor ./hosts/saturn/home.nix)
        ];
      };

      checks.x86_64-linux = nixpkgs.lib.mapAttrs
        (_: host: host.config.system.build.toplevel)
        self.nixosConfigurations;

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
