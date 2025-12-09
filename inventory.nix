{
  # Laptop Configuration
  # Base specs: NVMe drive, 34G Swap
  nix-laptop = {
    count = 2;
    devices = {
      # Override example:
      # "2" = { swapSize = "64G"; };
      
      # Enable specific users for this device index
      "1" = { extraUsers = [ "hdh20267" ]; };
      "2" = { extraUsers = [ "hdh20267" ]; };
      
      # Example of using an external flake for system configuration:
      # "2" = { flakeUrl = "github:user/system-flake"; };
    };
  };

  # Desktop Configuration
  # Base specs: NVMe drive, 16G Swap
  nix-desktop.count = 1;

  # Surface Tablet Configuration (Kiosk Mode)
  # Base specs: eMMC drive, 8G Swap
  nix-surface.count = 3;
}
