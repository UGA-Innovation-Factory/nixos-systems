{ pkgs, ... }:
{
  # Define the users here using the new option
  # To generate a password hash, run: mkpasswd -m sha-512
  modules.users.accounts = {
    root = {
      isNormalUser = false;
      hashedPassword = "!";
    };
    engr-ugaif = {
      description = "UGA Innovation Factory";
      extraGroups = [ "networkmanager" "wheel" "video" "input" ];
      hashedPassword = "$6$El6e2NhPrhVFjbFU$imlGZqUiizWw5fMP/ib0CeboOcFhYjIVb8oR1V1dP2NjDeri3jMoUm4ZABOB2uAF8UEDjAGHhFuZxhtbHg647/";
      opensshKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBC7xzHxY2BfFUybMvG4wHSF9oEAGzRiLTFEndLvWV/X hdh20267@engr733847d.engr.uga.edu" ];
    };
    hdh20267 = {
      description = "Hunter Halloran";
      extraGroups = [ "networkmanager" "wheel" ];
      homePackages = [ pkgs.ghostty ];
      # Example of using an external flake for configuration:
      # flakeUrl = "github:hdh20267/dotfiles";
    };
  };
}
