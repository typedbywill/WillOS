{ lib, stdenv, fetchurl, installShellFiles }:

stdenv.mkDerivation rec {
  pname = "wacli";
  version = "0.25.1";
  src = fetchurl {
    url = "https://github.com/openclaw/wacli/releases/download/v${version}/wacli_${version}_linux_amd64.tar.gz";
    sha256 = "53bbb450f0a47e3b080173d61fd6cec72241d8065bee17e592275983b7abd281";
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
