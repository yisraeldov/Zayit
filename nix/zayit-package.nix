{
  lib,
  stdenv,
  gradle_9,
  jbr,
  autoPatchelfHook,
  makeWrapper,
  runtimeLibs,
  seforimlibrary,
}:
let
  gradle = gradle_9.override {
    java = jbr;
    javaToolchains = [ jbr ];
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zayit";
  version = "unstable";

  src = ../.;

  nativeBuildInputs = [
    gradle
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = runtimeLibs;

  mitmCache = gradle.fetchDeps {
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  __darwinAllowLocalNetworking = true;

  gradleFlags = [
    "-Dfile.encoding=utf-8"
    "-Dorg.gradle.java.home=${jbr}"
    "-Dorg.gradle.java.installations.auto-detect=false"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jbr}"
  ];

  gradleBuildTask = ":SeforimApp:createReleaseDistributable";
  gradleUpdateTask = ":SeforimApp:createReleaseDistributable";
  doCheck = false;

  preConfigure = ''
    rm -rf SeforimLibrary
    cp -R --no-preserve=mode,ownership ${seforimlibrary} SeforimLibrary
    chmod -R u+w SeforimLibrary
  '';

  installPhase = ''
    runHook preInstall

    appDir="SeforimApp/build/compose/binaries/main-release/app/Zayit"
    if [ ! -d "$appDir" ]; then
      echo "Expected app directory at $appDir" >&2
      exit 1
    fi

    if [ ! -x "$appDir/bin/Zayit" ]; then
      echo "Expected launcher at $appDir/bin/Zayit" >&2
      exit 1
    fi

    install -d "$out/share/zayit"
    cp -R "$appDir"/. "$out/share/zayit/"
    chmod -R u+w "$out/share/zayit"

    install -d "$out/bin"
    makeWrapper "$out/share/zayit/bin/Zayit" "$out/bin/zayit" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"

    runHook postInstall
  '';

  meta = {
    description = "Desktop Torah study app";
    homepage = "https://github.com/kdroidFilter/Zayit";
    license = lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "zayit";
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode
    ];
  };
})
