{ pkgs, ... }:
let 
  pythonPkgs = import ./python.nix { inherit pkgs; };
in
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    root.hashedPassword = "!";
    engr-ugaif = {
      isNormalUser = true;
      description = "UGA Innovation Factory";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [
        kdePackages.kate
      ] ++ pythonPkgs;
      hashedPassword = "$6$El6e2NhPrhVFjbFU$imlGZqUiizWw5fMP/ib0CeboOcFhYjIVb8oR1V1dP2NjDeri3jMoUm4ZABOB2uAF8UEDjAGHhFuZxhtbHg647/";
    };

    hdh20267 = {
      isNormalUser = true;
      description = "Hunter Halloran";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [
        kdePackages.kate
      ] ++ pythonPkgs;
      shell = pkgs.zsh;
    };
  };
  
  # Home Manager configs per user
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users = {
      "engr-ugaif" = import ./engr-ugaif.nix;
      "hdh20267" = import ./hdh20267.nix;
      "root" = import ./root.nix;
    };
  };
}
