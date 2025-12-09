{ config, lib, pkgs, inputs, ... }:
lib.mkMerge [
  (import ./programs.nix { inherit config lib pkgs inputs; })
  (import ./services.nix { inherit config lib pkgs inputs; })
]
