{ user }:
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  nvimPackages =
    if user.useNvimPlugins then
      [
        inputs.lazyvim-nixvim.packages.${pkgs.stdenv.hostPlatform.system}.nvim
      ]
    else
      [ pkgs.neovim ];
in
{
  # ============================================================================
  # Neovim Configuration
  # ============================================================================
  # This module configures Neovim, specifically setting up TreeSitter parsers
  # to ensure syntax highlighting works correctly.

  home.packages = nvimPackages;

  # https://github.com/nvim-treesitter/nvim-treesitter#i-get-query-error-invalid-node-type-at-position
  xdg.configFile."nvim/parser".source = lib.mkIf user.useNvimPlugins (
    let
      parsers = pkgs.symlinkJoin {
        name = "treesitter-parsers";
        paths =
          (pkgs.vimPlugins.nvim-treesitter.withPlugins (
            plugins: with plugins; [
              c
              lua
            ]
          )).dependencies;
      };
    in
    "${parsers}/parser"
  );
}
