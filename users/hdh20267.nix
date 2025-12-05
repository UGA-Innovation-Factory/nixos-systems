{ pkgs, ... }:
let
  # Fetch upstream OMP theme once
  jyumppTheme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Jyumpp/jyumpp-zsh-theme/refs/heads/master/.jyumpp.omp.json";
    # After first build Nix will show the wanted hash; add it here for reproducibility:
    hash = "sha256-jsN3hkyT0dJNTYEmDHQPp++oscQLgYGNj7PZAcIW2TA=";
  };
in
{
  home.username = "hdh20267";
  home.homeDirectory = "/home/hdh20267";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    ghostty
  ];

  programs.plasma-manager.enable = true;
  xdg.configFile."kdeglobals".source = pkgs.writeText "kdeglobals" ''
    [General]
    TerminalApplication=${pkgs.ghostty}/bin/ghostty
  '';

  programs.zsh = {
    enable = true;

    # Plugins
    historySubstringSearch = {
      enable = true;
      searchDownKey = "^[[B";
      searchUpKey = "^[[A";
    };

    zplug = {
      enable = true;
      plugins = [
        {
          name = "jeffreytse/zsh-vi-mode";
        }
        {
          name = "BronzeDeer/zsh-completion-sync";
        }
      ];
    };

    history = {
      append = true;
    };

    autosuggestion.enable = true;

    syntaxHighlighting.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.lsd = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile(jyumppTheme)));
  };

  # https://github.com/nvim-treesitter/nvim-treesitter#i-get-query-error-invalid-node-type-at-position
  xdg.configFile."nvim/parser".source =
    let
      parsers = pkgs.symlinkJoin {
        name = "treesitter-parsers";
        paths = (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
          c
          lua
        ])).dependencies;
      };
    in
    "${parsers}/parser";

}
