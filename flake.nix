# /etc/nixos/flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazyvim-nixvim.url = "github:azuwis/lazyvim-nixvim";
  };
  outputs = inputs@{ self, nixpkgs, home-manager, disko, nixos-generators, lazyvim-nixvim, ... }: {
    nixosConfigurations = import ./hosts { inherit inputs; };
  };
}
