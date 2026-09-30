{ lib
, stdenv
, fetchurl
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
  version = "0.63.0";
  src = fetchurl {
    url = "https://downloads.cursor.com/grokbot/stable/76ea13a663a8e41e1664246c174c22291f9a9301/linux/x64/grok-bot_0.63.0_amd64.deb";
    sha256 = "68d89c4118633cffd45c1960e274bd15e7763c3378b11b7c7a433e2441bbca9a";
  };

  grok-bot-unpacked = stdenv.mkDerivation {
    pname = "grok-bot-unpacked";
    inherit version src;

    nativeBuildInputs = [ dpkg ];

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      mkdir -p $out
      cp -r opt $out/
      cp -r usr/* $out/
    '';
  };

in buildFHSEnv {
  name = "grok-bot";

  targetPkgs = pkgs: [
    grok-bot-unpacked
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

  runScript = "\"${grok-bot-unpacked}/opt/Grok Bot/grok-bot\"";

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/icons
    cp ${grok-bot-unpacked}/share/applications/grok-bot.desktop $out/share/applications/
    cp -r ${grok-bot-unpacked}/share/icons/* $out/share/icons/
  '';

  meta = with lib; {
    description = "Grok Bot desktop agent";
    homepage = "https://cursor.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "grok-bot";
  };
}
