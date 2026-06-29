{
  description = "NixOS Homeserver Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    
    compose2nix.url = "github:aksiksi/compose2nix";
    compose2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  # compose2nix.url = "github:aksiksi/compose2nix";
  # compose2nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/homeserver/default.nix
        ];
      };
    };
  };
}