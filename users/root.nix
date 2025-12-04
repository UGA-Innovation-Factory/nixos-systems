{ pkgs, ... }:

let
  # Fetch upstream OMP theme once
  jyumppTheme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Jyumpp/jyumpp-zsh-theme/refs/heads/master/.jyumpp.omp.json";
    # After first build Nix will show the wanted hash; add it here for reproducibility:
    sha256 = "sha256-jsN3hkyT0dJNTYEmDHQPp++oscQLgYGNj7PZAcIW2TA=";
  };

  # Make a root variant with red username (wraps {{ .UserName }} with ANSI red)
  jyumppRootTheme = pkgs.runCommand "jyumpp-root.omp.json" {} ''
    sed -E 's|\{\{[[:space:]]*\.UserName[[:space:]]*\}\}|<#FF3B30>{{ .UserName }}</>|g' \
      ${jyumppTheme} > $out
'';
in
{
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.05";

  programs.zsh = {
    enable = true;

    # Plugins
    historySubstringSearch = {
      enable = true;
      searchDownKey = "^[[B";
      searchUpKey = "^[[A";
    };

    history = {
      append = true;
    };

    autosuggestion.enable = true;

    syntaxHighlighting.enable = true;
  };

  programs.oh-my-posh = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile(jyumppRootTheme)));

  };

  # Add any root-specific HM packages if desired
  home.packages = [ ];
}
