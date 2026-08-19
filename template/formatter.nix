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

  programs.google-java-format = {
    enable = true;
    # loader shims contain scaffold tokens until a project is generated
    excludes = [
      "fabric/src/main/java/**/FabricEntry.java"
      "fabric/src/client/java/**/FabricClientEntry.java"
      "neoforge/src/main/java/**/NeoForgeEntry.java"
      "neoforge/src/main/java/**/NeoForgeClientEntry.java"
    ];
  };
  programs.ktfmt.enable = true;
  programs.nixfmt.enable = true;
  programs.prettier.enable = true;
  programs.statix.enable = true;
}
