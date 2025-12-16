{
  system = {
    path = ./system;
    description = "External NixOS system configuration module";
    welcomeText = ''
      # External System Configuration Template

      This template creates an external NixOS system configuration module
      that can be referenced from nixos-systems/inventory.nix.

      ## Quick Start

      1. Edit `default.nix` with your system configuration
      2. Commit to a Git repository
      3. Reference in inventory.nix using the `flakeUrl` field

      See README.md for detailed documentation.
    '';
  };

  user = {
    path = ./user;
    description = "External user home-manager configuration";
    welcomeText = ''
      # User Configuration Template

      This template creates an external user configuration module
      that can be referenced from nixos-systems/users.nix.

      ## Quick Start

      1. Edit `home.nix` with your home-manager configuration
      2. (Optional) Edit `nixos.nix` for system-level configuration
      3. Commit to a Git repository
      4. Reference in users.nix using the `flakeUrl` field

      See README.md for detailed documentation.
    '';
  };
}
