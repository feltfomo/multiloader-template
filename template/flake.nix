{
  description = "feltfomo multiloader template — toolchain + dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in {
      devShells = forAllSystems (pkgs:
        let
          # MC 26.1+ needs Java 25. If your channel lacks jdk25, swap in
          # pkgs.temurin-bin-25 or the newest pkgs.jdk available.
          jdk = pkgs.jdk25;
        in {
          default = pkgs.mkShell {
            packages = [ jdk pkgs.gradle pkgs.pkl ];
            JAVA_HOME = "${jdk}";
            shellHook = ''
              echo "multiloader dev shell ready"
              java -version
              pkl --version
            '';
          };
        });
    };
}
