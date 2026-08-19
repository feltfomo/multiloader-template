{
  description = "cargo-new style generator for the multiloader Minecraft mod template";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in {
      templates.default = {
        path = ./template;
        description =
          "Multiloader (Fabric + NeoForge) Minecraft mod: common-only with mixins, Java/Kotlin/Scala.";
        welcomeText = ''
          Multiloader template copied.

          1. personalize the placeholders
               nu scaffold.nu
          2. enter the dev shell and run a loader
               nix develop
               ./gradlew :fabric:runClient
               ./gradlew :neoforge:runClient
        '';
      };
      templates.mod = self.templates.default;

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${pkgs.writeShellApplication {
            name = "new-mc-mod";
            runtimeInputs = [
              pkgs.nushell
              pkgs.gnutar
              pkgs.coreutils
              pkgs.findutils
              pkgs.gnused
              pkgs.gnugrep
            ];
            text = ''
              exec nu ${self}/new-mc-mod.nu "$@"
            '';
          }}/bin/new-mc-mod";
        };
        new = self.apps.${pkgs.stdenv.hostPlatform.system}.default;
      });
    };
}
