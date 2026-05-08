{
  description = "NixOS Homeserver Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    
    compose2nix.url = "github:aksiksi/compose2nix";
    compose2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  compose2nix.url = "github:aksiksi/compose2nix";
  compose2nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, vscode-server, compose2nix, ... }: {
    nixosConfigurations = {
      homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/homeserver/default.nix
          vscode-server.nixosModules.default
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
        ];
      };
    };
  };
}