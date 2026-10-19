{ lib
, appimageTools
, fetchurl
, stdenv
}:

let
  pname = "lmstudio";
  version = "0.4.26-4";
  hash = "sha256-LGKjipOtA8pdqu8ogEiAvhZ1Zng/+vwXPOLhyxC3VS4=";
  url = "https://installers.lmstudio.ai/linux/x64/${version}/LM-Studio-${version}-x64.AppImage";
  src = fetchurl { inherit url hash; };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;
  meta = {
    description = "LM Studio is an easy to use desktop app for experimenting with local and open-source Large Language Models (LLMs)";
    homepage = "https://lmstudio.ai/";
    license = lib.licenses.unfree;
    mainProgram = "lm-studio";
    platforms = [ "x86_64-linux" ];
  };
  extraPkgs = p: [ p.ocl-icd ];
  extraInstallCommands = ''
    mkdir -p $out/share/icons
    cp -r ${appimageContents}/usr/share/icons/hicolor $out/share/icons/

    install -m 444 -D ${appimageContents}/ai.elementlabs.lmstudio.desktop \
      -t $out/share/applications

    mv $out/bin/lmstudio $out/bin/lm-studio

    substituteInPlace $out/share/applications/ai.elementlabs.lmstudio.desktop \
      --replace-fail 'Exec=AppRun %U' 'Exec=lm-studio %U'

    install -m 755 ${appimageContents}/resources/app/.webpack/lms $out/bin/

    patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" $out/bin/lms
  '';
}
