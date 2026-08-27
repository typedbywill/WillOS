{ symlinkJoin, winbox, makeWrapper, lib }:

symlinkJoin {
  name = "winbox";
  paths = [ winbox ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    rm $out/bin/WinBox
    makeWrapper ${winbox}/bin/WinBox $out/bin/WinBox \
      --set QT_QPA_PLATFORM xcb
    ln -sf $out/bin/WinBox $out/bin/winbox
  '';
  meta = winbox.meta // {
    mainProgram = "WinBox";
  };
}
