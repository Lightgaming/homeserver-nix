{
  description = "NixOS Homeserver Flake";

  inputs = {
    # Using 24.05 for server stability, though you can use nixos-unstable if preferred
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; 
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = { self, nixpkgs, vscode-server, ... }: {
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