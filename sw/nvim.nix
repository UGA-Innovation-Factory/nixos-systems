# ============================================================================
# Neovim Home Manager Configuration
# ============================================================================
# Provides conditional Neovim configuration based on user preferences.
# - If useNvimPlugins=true: Full LazyVim distribution with plugins
# - If useNvimPlugins=false: Plain Neovim without plugins

{ user }:
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # Choose Neovim package based on user preference
  nvimPackages =
    if user.useNvimPlugins then
      [ inputs.lazyvim-nixvim.packages.${pkgs.stdenv.hostPlatform.system}.nvim ]
    else
      [ pkgs.neovim ];
in
{

  home.packages = nvimPackages;

  # Configure TreeSitter parsers for syntax highlighting
  # Only needed when using plugins (LazyVim includes TreeSitter)
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
