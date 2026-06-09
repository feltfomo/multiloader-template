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

          # Native libs Minecraft's LWJGL/GLFW/OpenAL dlopen at runtime.
          # NixOS doesn't put these on the default loader path, so a dev
          # client crashes at window/GL init without them. Linux only.
          runtimeLibs = with pkgs; [
            libGL glfw openal libpulseaudio vulkan-loader flite
            xorg.libX11 xorg.libXcursor xorg.libXext xorg.libXrandr
            xorg.libXxf86vm xorg.libXi xorg.libXrender xorg.libXtst
            wayland libxkbcommon udev stdenv.cc.cc.lib
          ];
        in {
          default = pkgs.mkShell {
            packages = [ jdk pkgs.gradle pkgs.pkl ];
            JAVA_HOME = "${jdk}";
            shellHook = ''
              echo "multiloader dev shell ready"
              ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
                # so runClient (and IntelliJ launched from this shell) finds the GL/X11/wayland natives
                export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
              ''}
              java -version
              pkl --version
            '';
          };
        });
    };
}
