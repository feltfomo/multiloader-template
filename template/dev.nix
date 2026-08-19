{ pkgs, treefmt }:

let
  jdk = pkgs.jdk25;
  linuxRuntimeLibs = with pkgs; [
    alsa-lib
    flite
    glfw
    libGL
    libpulseaudio
    libx11
    libxcursor
    libxext
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxtst
    libxxf86vm
    openal
    stdenv.cc.cc.lib
    udev
    vulkan-loader
    wayland
  ];
in
pkgs.mkShell {
  packages = [
    jdk
    treefmt
  ]
  ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.vulkan-tools ];

  JAVA_HOME = "${jdk}";

  shellHook = ''
    ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
      export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath linuxRuntimeLibs}:/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    ''}
    echo "minecraft mod dev shell ready"
    java -version
  '';
}
