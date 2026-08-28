{ config, pkgs, lib, ... }:

let
  # Tempo limite de inatividade em segundos (5 minutos = 300s)
  idleTimeoutSeconds = 300;

  spotifyWatcherScript = pkgs.writeShellScriptBin "spotify-inactivity-watcher" ''
    set -euo pipefail

    STATE_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    STATE_FILE="$STATE_DIR/spotify-idle-since"

    # 1. Se o processo do Spotify não existe, limpa o estado e encerra
    if ! ${pkgs.procps}/bin/pgrep -x spotify >/dev/null 2>&1; then
      ${pkgs.coreutils}/bin/rm -f "$STATE_FILE"
      exit 0
    fi

    # 2. Consulta o status de reprodução do Spotify via MPRIS D-Bus
    STATUS="$(${pkgs.playerctl}/bin/playerctl -p spotify status 2>/dev/null || echo "Inactive")"

    # 3. Se estiver tocando música, reseta o temporizador de inatividade
    if [ "$STATUS" = "Playing" ]; then
      ${pkgs.coreutils}/bin/rm -f "$STATE_FILE"
      exit 0
    fi

    # 4. Caso esteja pausado, parado ou sem áudio ativo
    NOW="$(${pkgs.coreutils}/bin/date +%s)"

    if [ ! -f "$STATE_FILE" ]; then
      echo "$NOW" > "$STATE_FILE"
      exit 0
    fi

    SINCE="$(${pkgs.coreutils}/bin/cat "$STATE_FILE" 2>/dev/null || echo "$NOW")"
    ELAPSED=$(( NOW - SINCE ))

    # 5. Se o tempo inativo atingir ou ultrapassar o limite, encerra o Spotify
    if [ "$ELAPSED" -ge ${toString idleTimeoutSeconds} ]; then
      ${pkgs.procps}/bin/pkill -x spotify 2>/dev/null || true
      ${pkgs.coreutils}/bin/rm -f "$STATE_FILE"
    fi
  '';
in
{
  # Serviço oneshot disparado periodicamente pelo timer
  systemd.user.services.spotify-inactivity-watcher = {
    Unit = {
      Description = "Monitor de Inatividade do Spotify";
      Documentation = [ "man:playerctl(1)" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${spotifyWatcherScript}/bin/spotify-inactivity-watcher";
    };
  };

  # Timer em background gerenciado nativamente pelo systemd (zero consumo de CPU/RAM em espera)
  systemd.user.timers.spotify-inactivity-watcher = {
    Unit = {
      Description = "Timer para verificação de inatividade do Spotify";
    };
    Timer = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m";
      AccuracySec = "10s";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
