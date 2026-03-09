{
  description = "Nix flake for running Zayit desktop on Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        jdk = pkgs.jdk25;
        runtimeLibs = with pkgs; [
          alsa-lib
          at-spi2-atk
          at-spi2-core
          cairo
          cups
          dbus
          expat
          fontconfig
          freetype
          gdk-pixbuf
          glib
          gtk3
          harfbuzz
          libdrm
          libGL
          libxkbcommon
          mesa
          nspr
          nss
          pango
          stdenv.cc.cc.lib
          libice
          libsm
          libx11
          libxcursor
          libxext
          libxfixes
          libxi
          libxinerama
          libxrandr
          libxrender
          libxtst
          libxcb
          zlib
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            jdk
            gradle
            git
            pkg-config
          ];

          JAVA_HOME = "${jdk}/lib/openjdk";
          ORG_GRADLE_JAVA_HOME = "${jdk}/lib/openjdk";
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimeLibs;

          shellHook = ''
            export PATH="$JAVA_HOME/bin:$PATH"
            echo "Zayit desktop shell ready. Run: ./gradlew :SeforimApp:run"
          '';
        };

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScript "zayit-run" ''
            set -euo pipefail

            if [ ! -f "./gradlew" ]; then
              echo "Run this command from the repository root." >&2
              exit 1
            fi

            export JAVA_HOME="${jdk}/lib/openjdk"
            export ORG_GRADLE_JAVA_HOME="$JAVA_HOME"
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeLibs}:''${LD_LIBRARY_PATH:-}"

            exec bash ./gradlew :SeforimApp:run "$@"
          ''}";
        };
      }
    );
}
