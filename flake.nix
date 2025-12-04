{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    lazyvim-nixvim.url = "github:azuwis/lazyvim-nixvim";
  };
  outputs = inputs@{ self, nixpkgs, home-manager, disko, lazyvim-nixvim, nixos-hardware,... }: {
    nixosConfigurations = import ./hosts { inherit inputs; };
  };
}
