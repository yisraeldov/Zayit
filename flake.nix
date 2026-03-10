{
  description = "Nix flake for running Zayit desktop on Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    seforimlibrary = {
      url = "git+https://github.com/kdroidFilter/SeforimLibrary.git?rev=988cf2679ce14e9aeebd0d783b8dd3ad778b7cf8&submodules=1";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      seforimlibrary,
      ...
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        jbrSpec = {
          url = "https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk-25.0.1-linux-x64-b268.52.tar.gz";
          hash = "sha256-5ksddsDj93ThrSi0CYHAliji33yJsdyiMO/+4FLp62k=";
        };
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
        jbr = pkgs.stdenvNoCC.mkDerivation {
          pname = "jbr";
          version = "25.0.1-b268.52";
          src = pkgs.fetchzip {
            inherit (jbrSpec) url hash;
          };
          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = runtimeLibs;
          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
            cp -R . "$out/"
            runHook postInstall
          '';
        };

        zayit = pkgs.callPackage ./nix/zayit-package.nix {
          inherit jbr runtimeLibs seforimlibrary;
        };
      in
      {
        packages.default = zayit;
        packages.zayit = zayit;

        apps.default = {
          type = "app";
          program = "${zayit}/bin/zayit";
        };
        apps.zayit = {
          type = "app";
          program = "${zayit}/bin/zayit";
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            jbr
            gradle_9
            git
            pkg-config
          ];

          JAVA_HOME = jbr;
          ORG_GRADLE_JAVA_HOME = jbr;
          LD_LIBRARY_PATH = runtimeLibraryPath;

          shellHook = ''
            export PATH="$JAVA_HOME/bin:$PATH"
            echo "Zayit desktop shell ready. Run: ./gradlew :SeforimApp:run"
          '';
        };
      }
    );
}
