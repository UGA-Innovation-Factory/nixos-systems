{
  # ============================================================================
  # Flake Entry Point
  # ============================================================================
  # This file defines the inputs (dependencies) and outputs (configurations)
  # for the NixOS systems. It ties together the hardware, software, and user
  # configurations into deployable systems.

  inputs = {
    # Core NixOS package repository (Release 25.11)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Older kernel packages for Surface compatibility if needed
    nixpkgs-old-kernel.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Home Manager for user environment management
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disko for declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware quirks and configurations
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Neovim configuration
    lazyvim-nixvim.url = "github:azuwis/lazyvim-nixvim";

    # VS Code server for remote development
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS Generators for creating ISOs, LXC, etc.
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-old-kernel,
      home-manager,
      disko,
      lazyvim-nixvim,
      nixos-hardware,
      vscode-server,
      nixos-generators,
      ...
    }:
    let
      hosts = import ./hosts { inherit inputs; };
      system = "x86_64-linux";
    in
    {
      # Formatter for 'nix fmt'
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      # Generate NixOS configurations from hosts/default.nix
      nixosConfigurations = hosts.nixosConfigurations;

      packages.${system} = import ./artifacts.nix {
        inherit inputs hosts self system;
      };
    };
}
