{
  description = "cargo-new style generator for the multiloader Minecraft mod template";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in {
      # `nix flake new -t github:OWNER/REPO ./my-mod` drops the real, tested
      # template into place. Then run ./scaffold.sh to make it yours.
      templates.default = {
        path = ./template;
        description =
          "Multiloader (Fabric + NeoForge) Minecraft mod: common-only with mixins, Java/Kotlin/Scala.";
        welcomeText = ''
          Multiloader template copied.

          1. personalize the placeholders (modid / Modid / com.example.modid / yourname):
               ./scaffold.sh
          2. enter the dev shell and run a loader:
               nix develop
               ./gradlew :fabric:runClient
               ./gradlew :neoforge:runClient
        '';
      };
      templates.mod = self.templates.default;

      # the closest thing to `cargo new`: copy + substitute in one command.
      #   nix run github:OWNER/REPO -- <mod_id> <group> [display name]
      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${pkgs.writeShellApplication {
            name = "new-mc-mod";
            runtimeInputs = [
              pkgs.bash pkgs.coreutils pkgs.findutils pkgs.gnused pkgs.gnugrep
            ];
            text = ''
              id="''${1:-}"
              group="''${2:-}"
              name="''${3:-}"
              if [ -z "$id" ] || [ -z "$group" ]; then
                echo "usage: nix run <flake> -- <mod_id> <group> [display name]" >&2
                echo "   eg: nix run <flake> -- coolmod com.acme.coolmod 'Cool Mod'" >&2
                exit 2
              fi
              if [ -e "$id" ]; then
                echo "error: ./$id already exists" >&2
                exit 1
              fi
              cp -rT --no-preserve=mode,ownership ${self}/template "$id"
              chmod -R u+w "$id"
              cd "$id"
              SCAFFOLD_ID="$id" SCAFFOLD_GROUP="$group" SCAFFOLD_NAME="$name" \
                bash ./scaffold.sh --non-interactive
              echo "created ./$id"
            '';
          }}/bin/new-mc-mod";
        };
        new = self.apps.${pkgs.system}.default;
      });
    };
}
