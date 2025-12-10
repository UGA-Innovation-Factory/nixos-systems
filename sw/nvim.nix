{ pkgs, ... }:
{
  # ============================================================================
  # Neovim Configuration
  # ============================================================================
  # This module configures Neovim, specifically setting up TreeSitter parsers
  # to ensure syntax highlighting works correctly.

  # https://github.com/nvim-treesitter/nvim-treesitter#i-get-query-error-invalid-node-type-at-position
  xdg.configFile."nvim/parser".source =
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
    "${parsers}/parser";
}
