{ lib, stdenv, fetchurl, installShellFiles }:

stdenv.mkDerivation rec {
  pname = "wacli";
  version = "0.26.1";
  src = fetchurl {
    url = "https://github.com/openclaw/wacli/releases/download/v${version}/wacli_${version}_linux_amd64.tar.gz";
    sha256 = "515405c5a33c7f651a368484740db662736f50c275be5a0504fb0a84dce47013";
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
