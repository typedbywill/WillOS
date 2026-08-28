{ lib
, stdenv
, dpkg
, buildFHSEnv
, alsa-lib
, at-spi2-atk
, at-spi2-core
, atk
, cairo
, cups
, curl
, dbus
, expat
, gdk-pixbuf
, glib
, gtk3
, libdrm
, libgbm
, libglvnd
, libnotify
, libpulseaudio
, libsecret
, libusb1
, libxkbcommon
, mesa
, nspr
, nss
, pango
, systemd
, vulkan-loader
, libx11
, libxscrnsaver
, libxcomposite
, libxcursor
, libxdamage
, libxext
, libxfixes
, libxi
, libxrandr
, libxrender
, libxtst
, libxcb
, libxshmfence
, wayland
, zlib
, xdg-utils
}:

let
  version = "26.818.61809";
  src = builtins.fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
  };

  chatgpt-unpacked = stdenv.mkDerivation {
    pname = "chatgpt-unpacked";
    inherit version src;

    nativeBuildInputs = [ dpkg ];

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      mkdir -p $out
      cp -r usr/* $out/
    '';
  };

in buildFHSEnv {
  name = "chatgpt";

  targetPkgs = pkgs: [
    chatgpt-unpacked
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    curl
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libglvnd
    libnotify
    libpulseaudio
    libsecret
    libusb1
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    vulkan-loader
    libx11
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    libxcb
    libxshmfence
    wayland
    zlib
    xdg-utils
    pkgs.stdenv.cc.cc.lib
  ];

  runScript = "${chatgpt-unpacked}/bin/chatgpt";

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/pixmaps $out/share/icons/hicolor/512x512/apps
    cp ${chatgpt-unpacked}/share/applications/chatgpt.desktop $out/share/applications/
    cp ${chatgpt-unpacked}/share/pixmaps/chatgpt.png $out/share/pixmaps/
    cp ${chatgpt-unpacked}/share/pixmaps/chatgpt.png $out/share/icons/hicolor/512x512/apps/chatgpt.png
  '';

  meta = with lib; {
    description = "ChatGPT desktop application for Linux";
    homepage = "https://learn.chatgpt.com/docs/linux/linux-app";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "chatgpt";
  };
}
