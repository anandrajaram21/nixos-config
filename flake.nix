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
  };

  outputs = { nixpkgs, home-manager, disko, ... }:
    let
      homeManagerFor = homeFile: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.altf4 = import homeFile;
      };
    in
    {
      nixosConfigurations.saturn = nixpkgs.lib.nixosSystem {
        modules = [
          disko.nixosModules.disko
          ./hosts/saturn/configuration.nix
          home-manager.nixosModules.home-manager
          (homeManagerFor ./hosts/saturn/home.nix)
        ];
      };
    };
}
