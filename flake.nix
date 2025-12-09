{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-old-kernel.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    lazyvim-nixvim.url = "github:azuwis/lazyvim-nixvim";
  };
  outputs = inputs@{ self, nixpkgs, nixpkgs-old-kernel, home-manager, disko, lazyvim-nixvim, nixos-hardware,... }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

    nixosConfigurations = import ./hosts { inherit inputs; };
  };
}
