{
  projectRootFile = "flake.nix";

  settings.global.excludes = [
    "**/.gradle/**"
    "**/.jdk/**"
    "**/.kotlin/**"
    "**/build/**"
    "**/generated/**"
    "**/run/**"
  ];

  programs.google-java-format.enable = true;
  programs.ktfmt.enable = true;
  programs.nixfmt.enable = true;
  programs.prettier.enable = true;
  programs.statix.enable = true;
}
