{ lib, stdenv, fetchurl, installShellFiles }:

stdenv.mkDerivation rec {
  pname = "wacli";
  version = "0.19.0";

  src = fetchurl {
    url = "https://github.com/openclaw/wacli/releases/download/v${version}/wacli_${version}_linux_amd64.tar.gz";
    sha256 = "57ea00b26c0ffefa29758b2bcfc183b3e7b061271afee21cb0471a024f3c57ff";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -m755 -D wacli $out/bin/wacli
    ln -s $out/bin/wacli $out/bin/wahcli

    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${lib.makeLibraryPath [ stdenv.cc.libc ]}" \
      $out/bin/wacli

    installShellCompletion --cmd wacli \
      --bash <($out/bin/wacli completion bash) \
      --fish <($out/bin/wacli completion fish) \
      --zsh <($out/bin/wacli completion zsh)

    installShellCompletion --cmd wahcli \
      --bash <($out/bin/wacli completion bash) \
      --fish <($out/bin/wacli completion fish) \
      --zsh <($out/bin/wacli completion zsh)

    runHook postInstall
  '';

  meta = with lib; {
    description = "WhatsApp CLI: sync, search, and send messages from terminal";
    homepage = "https://wacli.sh";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "wacli";
  };
}
