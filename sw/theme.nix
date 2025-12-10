{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:

# ============================================================================
# Shell Theme Configuration
# ============================================================================
# This module configures the shell environment (Zsh, Oh My Posh) for users.
# It is imported by default for all users to ensure a consistent experience.

let
  # Fetch upstream OMP theme once
  jyumppTheme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Jyumpp/jyumpp-zsh-theme/refs/heads/master/.jyumpp.omp.json";
    hash = "sha256-jsN3hkyT0dJNTYEmDHQPp++oscQLgYGNj7PZAcIW2TA=";
  };

  # Make a root variant with red username (wraps {{ .UserName }} with ANSI red)
  jyumppRootTheme = pkgs.runCommand "jyumpp-root.omp.json" { } ''
    sed -E 's|\{\{[[:space:]]*\.UserName[[:space:]]*\}\}|<#FF3B30>{{ .UserName }}</>|g' \
      ${jyumppTheme} > $out
  '';

  isRoot = config.home.username == "root";
  themeFile = if isRoot then jyumppRootTheme else jyumppTheme;
in
{
  config = {
    programs.zsh = {
      enable = true;

      # Plugins
      historySubstringSearch = {
        enable = true;
        searchDownKey = "^[[B";
        searchUpKey = "^[[A";
      };

      zplug = lib.mkIf (!isRoot) {
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

    programs.zoxide = lib.mkIf (!isRoot) {
      enable = true;
      enableZshIntegration = true;
    };

    programs.lsd = lib.mkIf (!isRoot) {
      enable = true;
      enableZshIntegration = true;
    };

    programs.oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile themeFile));
    };
  };
}
