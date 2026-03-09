{
  description = "Nix flake for running Zayit desktop on Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    seforimlibrary = {
      url = "git+https://github.com/kdroidFilter/SeforimLibrary.git?submodules=1";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      seforimlibrary,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        jdk = pkgs.jdk25;
        sourceRev = self.rev or (self.dirtyRev or "dirty");
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
        runtimeLibraryPath = pkgs.lib.makeLibraryPath runtimeLibs;
      in
      rec {
        packages.default = pkgs.writeShellApplication {
          name = "zayit";
          runtimeInputs = with pkgs; [
            bash
            coreutils
            rsync
          ];
          text = ''
            set -euo pipefail

            cacheRoot="''${XDG_CACHE_HOME:-$HOME/.cache}/zayit"
            sourceRev="${sourceRev}"
            cacheKey="$sourceRev-v2"
            workspaceDir="$cacheRoot/workspace-$cacheKey"
            bootstrapMarker="$workspaceDir/.bootstrap-complete"

            install -d "$cacheRoot"

            if [ ! -f "$bootstrapMarker" ]; then
              tmpDir="$cacheRoot/workspace-bootstrap-$$"
              rm -rf "$tmpDir"
              install -d "$tmpDir"

              rsync -rlt --delete --chmod=Du+rwx,Fu+rw --exclude '.gradle' --exclude 'build' --exclude 'SeforimLibrary' "${self}/" "$tmpDir/"

              rsync -rlt --delete --chmod=Du+rwx,Fu+rw "${seforimlibrary}/" "$tmpDir/SeforimLibrary/"

              chmod -R u+w "$tmpDir"
              touch "$tmpDir/.bootstrap-complete"

              rm -rf "$workspaceDir" || true
              mv "$tmpDir" "$workspaceDir"
            fi

            cd "$workspaceDir"

            export JAVA_HOME="${jdk}/lib/openjdk"
            export ORG_GRADLE_JAVA_HOME="$JAVA_HOME"
            export LD_LIBRARY_PATH="${runtimeLibraryPath}:''${LD_LIBRARY_PATH:-}"

            exec bash ./gradlew :SeforimApp:run "$@"
          '';
        };

        packages.zayit = packages.default;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            jdk
            gradle
            git
            pkg-config
          ];

          JAVA_HOME = "${jdk}/lib/openjdk";
          ORG_GRADLE_JAVA_HOME = "${jdk}/lib/openjdk";
          LD_LIBRARY_PATH = runtimeLibraryPath;

          shellHook = ''
            export PATH="$JAVA_HOME/bin:$PATH"
            echo "Zayit desktop shell ready. Run: ./gradlew :SeforimApp:run"
          '';
        };

        apps.default = {
          type = "app";
          program = "${packages.default}/bin/zayit";
        };

        apps.zayit = apps.default;
      }
    );
}
