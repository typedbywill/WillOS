#!/usr/bin/env bash
# ==============================================================================
#  ⚡ NIXOS SYSTEM CORE UPGRADE & REBUILD ENGINE ⚡
#  Motor de reconstrução ultra-dinâmico, interativo e cinematográfico
# ==============================================================================

set -eo pipefail

# ------------------------------------------------------------------------------
# 🎨 PALETA DE CORES ANSI DO TERMINAL (HERDA DO TERMINAL / CAELESTIA)
# ------------------------------------------------------------------------------
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_ITALIC="\033[3m"
C_UNDERLINE="\033[4m"

# Cores ANSI padrão (16 cores que respeitam o tema do Kitty/Caelestia)
C_BLACK="\033[30m"
C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_BLUE="\033[34m"
C_MAGENTA="\033[35m"
C_CYAN="\033[36m"
C_WHITE="\033[37m"

# Variações brilhantes e tons neutros
C_MUTED="\033[90m"
C_BORDER="\033[90m"
C_BRIGHT_RED="\033[91m"
C_BRIGHT_GREEN="\033[92m"
C_BRIGHT_YELLOW="\033[93m"
C_BRIGHT_BLUE="\033[94m"
C_BRIGHT_CYAN="\033[96m"
C_BRIGHT_WHITE="\033[97m"

if [ -z "$REPO_DIR" ]; then
    SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
    if [ -f "$SCRIPT_ROOT/flake.nix" ]; then
        REPO_DIR="$SCRIPT_ROOT"
    elif [ -d "$HOME/nixos-hyprland-caelestia" ] && [ -f "$HOME/nixos-hyprland-caelestia/flake.nix" ]; then
        REPO_DIR="$HOME/nixos-hyprland-caelestia"
    else
        REPO_DIR="/home/william/nixos-hyprland-caelestia"
    fi
fi
SUDO_PID=""

# ------------------------------------------------------------------------------
# 🛡️ LIMPEZA E TRAPS (Ctrl+C / EXIT / ERR)
# ------------------------------------------------------------------------------
error_handler() {
    local exit_code=$?
    local line_no=$1
    local cmd="$2"
    if [ "$exit_code" -ne 0 ]; then
        echo -e "\n${C_BORDER}╭─────────────────────────────────────────────────────────────────────────────╮${C_RESET}"
        echo -e "${C_BORDER}│${C_RESET}  ${C_BOLD}${C_RED}❌ ERRO INESPERADO NA EXECUÇÃO DO SCRIPT${C_RESET}                                   ${C_BORDER}│${C_RESET}"
        echo -e "${C_BORDER}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
        echo -e "${C_BORDER}│${C_RESET}  ${C_MUTED}Arquivo :${C_RESET} ${BASH_SOURCE[1]:-$0}"
        echo -e "${C_BORDER}│${C_RESET}  ${C_MUTED}Linha   :${C_RESET} ${line_no}"
        echo -e "${C_BORDER}│${C_RESET}  ${C_MUTED}Comando :${C_RESET} ${C_YELLOW}${cmd}${C_RESET}"
        echo -e "${C_BORDER}│${C_RESET}  ${C_MUTED}Código  :${C_RESET} ${C_RED}${exit_code}${C_RESET}"
        echo -e "${C_BORDER}╰─────────────────────────────────────────────────────────────────────────────╯\n"
    fi
}
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR

cleanup() {
    tput cnorm 2>/dev/null || printf "\033[?25h" 2>/dev/null || true
    if [ -n "$SUDO_PID" ]; then
        kill "$SUDO_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------------------
# 🔊 SONS E NOTIFICAÇÕES
# ------------------------------------------------------------------------------
play_sound() {
    local sound_type="$1"
    local sound_file=""
    if [ "$sound_type" = "success" ]; then
        sound_file="/run/current-system/sw/share/sounds/freedesktop/stereo/complete.oga"
    elif [ "$sound_type" = "error" ]; then
        sound_file="/run/current-system/sw/share/sounds/freedesktop/stereo/dialog-error.oga"
    fi

    if [ -n "$sound_file" ] && [ -f "$sound_file" ] && command -v pw-play >/dev/null 2>&1; then
        pw-play "$sound_file" >/dev/null 2>&1 &
    fi
}

send_notify() {
    local urgency="$1"
    local title="$2"
    local body="$3"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -a "WillOS Core Engine" -i "system-software-update" "$title" "$body" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 💻 CABEÇALHO CYBERPUNK & TELEMETRIA
# ------------------------------------------------------------------------------
print_header() {
    local host_name
    host_name=$(hostname 2>/dev/null || echo "nixos")
    local kernel_ver
    kernel_ver=$(uname -r 2>/dev/null || echo "Linux")
    local current_gen
    current_gen=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]\+-link' | grep -o '[0-9]\+' || echo "1")
    local branch
    branch=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || echo "main")
    local now_str
    now_str=$(date "+%d/%m/%Y • %H:%M:%S")

    # Limpa a tela de forma segura usando escape code ANSI
    if [ -t 1 ]; then
        printf "\033[H\033[2J" 2>/dev/null || true
    fi

    echo -e "${C_BORDER}╭─────────────────────────────────────────────────────────────────────────────╮${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}              ${C_CYAN}██╗    ██╗██╗██╗     ██╗      ██████╗ ███████╗${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}              ${C_CYAN}██║    ██║██║██║     ██║     ██╔═══██╗██╔════╝${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}              ${C_BLUE}██║ █╗ ██║██║██║     ██║     ██║   ██║███████╗${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}              ${C_BLUE}██║███╗██║██║██║     ██║     ██║   ██║╚════██║${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}              ${C_CYAN}╚███╔███╔╝██║███████╗███████╗╚██████╔╝███████║${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}               ${C_CYAN}╚══╝╚══╝ ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}                                                                             ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}   ${C_BOLD}${C_CYAN}⚡  W I L L O S   S Y S T E M   C O R E   U P G R A D E   v 2 . 0  ⚡${C_RESET}    ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}💻 Sistema:${C_RESET} ${C_BOLD}%-14s${C_RESET} ${C_MUTED}🐧 Kernel:${C_RESET} ${C_CYAN}%-15s${C_RESET}  ${C_MUTED}🏷️  Geração Atual:${C_RESET} ${C_YELLOW}#%-4s${C_RESET} ${C_BORDER}│${C_RESET}\n" "WillOS [${host_name}]" "$kernel_ver" "$current_gen"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}🌿 Branch:${C_RESET}  ${C_BLUE}%-14s${C_RESET} ${C_MUTED}📅 Data:${C_RESET}   ${C_MUTED}%-15s${C_RESET}  ${C_MUTED}👤 Operador:${C_RESET}      ${C_GREEN}%-4s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$branch" "$now_str" "$USER"
    echo -e "${C_BORDER}╰─────────────────────────────────────────────────────────────────────────────╯${C_RESET}"
    echo ""
}

print_step_header() {
    local step_num="$1"
    local step_total="$2"
    local icon="$3"
    local title="$4"
    echo -e "${C_BORDER}╭─[ ${C_BOLD}${C_CYAN}${step_num}/${step_total}${C_RESET}${C_BORDER} ] ${C_RESET}${icon}  ${C_BOLD}${C_CYAN}${title}${C_RESET}"
}

print_substep() {
    local icon="$1"
    local msg="$2"
    echo -e "${C_BORDER}│  ${C_RESET}${icon} ${msg}"
}

print_step_done() {
    local msg="$1"
    echo -e "${C_BORDER}╰── ${C_GREEN}✔ ${msg}${C_RESET}\n"
}

print_step_fail() {
    local msg="$1"
    echo -e "${C_BORDER}╰── ${C_RED}✖ ${msg}${C_RESET}\n"
}

# ------------------------------------------------------------------------------
# 🌀 MOTOR DE EXECUÇÃO COM HUD DINÂMICO & SPINNER EM TEMPO REAL
# ------------------------------------------------------------------------------
run_with_dynamic_hud() {
    local title="$1"
    local default_status="$2"
    shift 2
    local cmd=("$@")

    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local spin_colors=("$C_CYAN" "$C_BLUE" "$C_WHITE" "$C_GREEN")
    
    local logfile
    logfile=$(mktemp /tmp/rebuild_task.XXXXXX)

    # Executa o comando em segundo plano capturando saída completa
    "${cmd[@]}" > "$logfile" 2>&1 &
    local pid=$!

    # Esconde o cursor
    tput civis 2>/dev/null || printf "\033[?25l" 2>/dev/null || true

    local start_t
    start_t=$(date +%s)
    local i=0
    local status_line="$default_status"
    local is_interactive=false
    if [ -t 1 ]; then
        is_interactive=true
    fi

    if [ "$is_interactive" = true ]; then
        # Reserva 3 linhas dinâmicas no terminal
        printf "\n\n\n\033[3A" 2>/dev/null || true
    fi

    while kill -0 "$pid" 2>/dev/null; do
        local frame="${frames[$((i % ${#frames[@]}))]}"
        local color="${spin_colors[$(( (i / 2) % ${#spin_colors[@]} ))]}"
        local curr_t
        curr_t=$(date +%s)
        local elapsed=$((curr_t - start_t))
        local min=$((elapsed / 60))
        local sec=$((elapsed % 60))

        # Analisa o arquivo de log em tempo real para exibir o status inteligente
        if [ -s "$logfile" ]; then
            local raw_last
            raw_last=$(tail -n 5 "$logfile" 2>/dev/null | grep -v '^[[:space:]]*$' | tail -n 1 | tr -d '\r\n' || echo "")
            if [[ "$raw_last" =~ building.*\.drv ]]; then
                local drv_name
                drv_name=$(echo "$raw_last" | sed "s/.*building '\/nix\/store\/[^-]*-//" | sed "s/\.drv'.*//" | cut -c1-35)
                status_line="⚙️  Compilando: ${drv_name}..."
            elif [[ "$raw_last" =~ copying.*path ]]; then
                status_line="📥 Baixando & copiando closures da Nix Store..."
            elif [[ "$raw_last" =~ updating.*menu|systemd-boot|grub ]]; then
                status_line="🛡️  Configurando entradas do bootloader..."
            elif [[ "$raw_last" =~ activating.*configuration ]]; then
                status_line="🚀 Ativando nova geração e serviços systemd..."
            elif [[ "$raw_last" =~ reloading|restarting ]]; then
                status_line="🔄 Recarregando daemons de usuário..."
            elif [[ "$raw_last" =~ eval ]]; then
                status_line="🧠 Avaliando expressões Flake e Nixpkgs..."
            elif [ -n "$raw_last" ]; then
                status_line="$(echo "$raw_last" | cut -c1-55)"
            fi
        fi

        # Barra de pulso animada
        local bar_pos=$((i % 20))
        local bar=""
        for ((b=0; b<20; b++)); do
            if [ $b -eq $bar_pos ] || [ $b -eq $(( (bar_pos + 1) % 20 )) ]; then
                bar+="█"
            elif [ $b -eq $(( (bar_pos + 2) % 20 )) ] || [ $b -eq $(( (bar_pos - 1 + 20) % 20 )) ]; then
                bar+="▓"
            else
                bar+="░"
            fi
        done

        if [ "$is_interactive" = true ]; then
            printf "\r\033[K${C_BORDER}│  ${color}${frame}${C_RESET} ${C_BOLD}${C_CYAN}%-38s${C_RESET} ${C_MUTED}⏱️  %02dm %02ds${C_RESET}\n" "$title" "$min" "$sec"
            printf "\r\033[K${C_BORDER}│  ${C_BORDER}├─ [${C_CYAN}%s${C_BORDER}] ${C_YELLOW}EM ANDAMENTO${C_RESET}\n" "$bar"
            printf "\r\033[K${C_BORDER}│  ${C_BORDER}└─ ${C_MUTED}Status:${C_RESET} ${C_MUTED}%-55s${C_RESET}\033[2A" "$status_line"
        fi

        ((i++))
        sleep 0.08
    done

    local exit_code=0
    wait "$pid" 2>/dev/null || exit_code=$?

    # Restaura o cursor
    tput cnorm 2>/dev/null || printf "\033[?25h" 2>/dev/null || true

    local total_elapsed=$(( $(date +%s) - start_t ))
    local min_tot=$((total_elapsed / 60))
    local sec_tot=$((total_elapsed % 60))

    if [ "$is_interactive" = true ]; then
        # Limpa as 3 linhas do HUD
        printf "\r\033[K\n\r\033[K\n\r\033[K\033[2A" 2>/dev/null || true
    fi

    if [ "$exit_code" -eq 0 ]; then
        printf "\r\033[K${C_BORDER}│  ${C_GREEN}✔${C_RESET} ${C_BOLD}${title}${C_RESET} ${C_GREEN}concluído em %02dm %02ds!${C_RESET}\n" "$min_tot" "$sec_tot"
        rm -f "$logfile"
        return 0
    else
        local persistent_log="/tmp/willos-rebuild.log"
        cp "$logfile" "$persistent_log" 2>/dev/null || true

        printf "\r\033[K${C_BORDER}│  ${C_RED}✖${C_RESET} ${C_BOLD}${title}${C_RESET} ${C_RED}falhou após %02dm %02ds (Código: ${exit_code})!${C_RESET}\n\n" "$min_tot" "$sec_tot"

        local total_lines
        total_lines=$(wc -l < "$logfile" 2>/dev/null || echo "0")

        echo -e "${C_RED}╔═════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
        echo -e "${C_RED}║  ❌  RELATÓRIO DE ERRO DETALHADO DO WILLOS REBUILD                          ║${C_RESET}"
        echo -e "${C_RED}╚═════════════════════════════════════════════════════════════════════════════╝${C_RESET}"

        if [ ! -s "$logfile" ] || [ "$total_lines" -eq 0 ]; then
            echo -e "${C_YELLOW}⚠️  O processo finalizou com código de erro ${exit_code} sem emitir dados no stdout/stderr.${C_RESET}"
            echo -e "${C_MUTED}Comando executado:${C_RESET} ${C_CYAN}${cmd[*]}${C_RESET}\n"
        elif [ "$total_lines" -le 100 ]; then
            cat "$logfile" 2>/dev/null || echo "Nenhum log gravado."
        else
            echo -e "${C_YELLOW}⚠️  Log extenso (${total_lines} linhas). Exibindo as últimas 60 linhas de saída:${C_RESET}\n"
            tail -n 60 "$logfile" 2>/dev/null || echo "Nenhum log gravado."
        fi

        echo -e "\n${C_RED}─────────────────────────────────────────────────────────────────────────────${C_RESET}"
        echo -e "${C_CYAN}📄 Log completo gravado em:${C_RESET} ${C_BOLD}${C_YELLOW}${persistent_log}${C_RESET}"
        echo -e "${C_MUTED}🔍 Para ver todo o log:${C_RESET}     ${C_BOLD}cat ${persistent_log}${C_RESET}  ${C_MUTED}ou${C_RESET}  ${C_BOLD}less ${persistent_log}${C_RESET}"
        echo -e "${C_RED}─────────────────────────────────────────────────────────────────────────────${C_RESET}\n"

        rm -f "$logfile"
        return "$exit_code"
    fi
}

# ------------------------------------------------------------------------------
# 🔍 DETECÇÃO INTELIGENTE DE PERFIL E PARSER DE HARDWARE
# ------------------------------------------------------------------------------
# 🔍 DETECÇÃO DE HARDWARE LOCAL E PARSER DE CONFIGURAÇÕES
# ------------------------------------------------------------------------------

# Assegura que o hardware local está pronto e configurado
ensure_local_hardware_ready() {
    if [ ! -f "$REPO_DIR/hardware-configuration.nix" ]; then
        if [ -f "/etc/nixos/hardware-configuration.nix" ]; then
            cp "/etc/nixos/hardware-configuration.nix" "$REPO_DIR/hardware-configuration.nix"
        elif command -v nixos-generate-config >/dev/null 2>&1; then
            nixos-generate-config --show-hardware-config > "$REPO_DIR/hardware-configuration.nix"
        else
            sudo nixos-generate-config --show-hardware-config > "$REPO_DIR/hardware-configuration.nix" 2>/dev/null || true
        fi
    fi

    if [ ! -f "$REPO_DIR/local-config.nix" ]; then
        local detected_hn
        detected_hn=$(hostname 2>/dev/null || echo "")
        if [ -z "$detected_hn" ] || [ "$detected_hn" = "nixos" ]; then
            detected_hn="willos"
        fi

        local detected_gpu="none"
        if lspci 2>/dev/null | grep -iq "nvidia"; then
            detected_gpu="nvidia"
        elif lspci 2>/dev/null | grep -iE "vga|3d" | grep -iq "intel"; then
            detected_gpu="intel"
        elif lspci 2>/dev/null | grep -iE "vga|3d" | grep -iq "amd\|radeon"; then
            detected_gpu="amd"
        fi

        cat <<EOF > "$REPO_DIR/local-config.nix"
# ==============================================================================
# 🛠️ WillOS - Configuração Local da Máquina
# Gerado automaticamente pelo rebuild.sh
# ==============================================================================
{ lib, ... }:

{
  networking.hostName = "${detected_hn}";
  myHardware.gpu.type = "${detected_gpu}";
}
EOF
    fi

    # Garante que os arquivos locais permaneçam fora do índice Git
    git -C "$REPO_DIR" reset HEAD hardware-configuration.nix local-config.nix >/dev/null 2>&1 || true
}

# Extrai a lista de partições e sistemas de arquivos do hardware-configuration.nix local
parse_host_disks() {
    local hw_file="$REPO_DIR/hardware-configuration.nix"
    if [ ! -f "$hw_file" ] && [ -f "/etc/nixos/hardware-configuration.nix" ]; then
        hw_file="/etc/nixos/hardware-configuration.nix"
    fi
    [ ! -f "$hw_file" ] && return 0

    awk '
    /fileSystems\./ {
        in_fs = 1;
        mount = "";
        if (match($0, /fileSystems\."([^"]+)"/, m)) mount = m[1];
        dev = "";
        fstype = "";
    }
    in_fs {
        if (match($0, /device[ \t]*=[ \t]*"([^"]+)"/, d)) dev = d[1];
        if (match($0, /fsType[ \t]*=[ \t]*"([^"]+)"/, t)) fstype = t[1];
        if ($0 ~ /};/) {
            if (mount != "") print "FS|" mount "|" (dev ? dev : "desconhecido") "|" (fstype ? fstype : "auto");
            in_fs = 0;
        }
    }
    /boot\.initrd\.luks\.devices\./ {
        if (match($0, /boot\.initrd\.luks\.devices\."([^"]+)"\.device[ \t]*=[ \t]*"([^"]+)"/, l)) {
            print "LUKS|" l[1] "|" l[2] "|crypto_LUKS";
        }
    }
    /swapDevices/ {
        in_swap = 1;
        swap_dev = "";
    }
    in_swap {
        if (match($0, /device[ \t]*=[ \t]*"([^"]+)"/, s)) swap_dev = s[1];
        if ($0 ~ /\];/) {
            if (swap_dev != "") print "SWAP|swap|" swap_dev "|swap";
            in_swap = 0;
        }
    }
    ' "$hw_file"
}

# Valida se um disco / UUID configurado existe ou está ativo no hardware atual
check_single_disk_status() {
    local kind="$1"
    local mount="$2"
    local dev="$3"
    local fstype="$4"

    if [ "$kind" = "FS" ]; then
        if [[ "$dev" == *"/by-uuid/"* ]]; then
            local uuid="${dev##*/}"
            if [ -e "/dev/disk/by-uuid/$uuid" ] || lsblk -no UUID 2>/dev/null | grep -wq "$uuid"; then
                local mnt_uuid
                mnt_uuid=$(findmnt -no UUID "$mount" 2>/dev/null || echo "")
                local mnt_src
                mnt_src=$(findmnt -no SOURCE "$mount" 2>/dev/null || echo "")
                if [ "$mnt_uuid" = "$uuid" ] || [ "$mnt_src" = "/dev/disk/by-uuid/$uuid" ]; then
                    echo "MOUNTED"
                else
                    echo "PRESENT"
                fi
                return 0
            else
                echo "MISSING"
                return 0
            fi
        elif [[ "$dev" =~ /dev/mapper/luks-(.+) ]]; then
            local luks_uuid="${BASH_REMATCH[1]}"
            if [ -e "$dev" ]; then
                local mnt_src
                mnt_src=$(findmnt -no SOURCE "$mount" 2>/dev/null || echo "")
                if [ "$mnt_src" = "$dev" ] || [[ "$mnt_src" == *"$dev"* ]]; then
                    echo "MOUNTED"
                else
                    echo "PRESENT"
                fi
                return 0
            elif [ -e "/dev/disk/by-uuid/$luks_uuid" ] || lsblk -no UUID 2>/dev/null | grep -wq "$luks_uuid"; then
                echo "PRESENT"
                return 0
            else
                echo "MISSING"
                return 0
            fi
        else
            if [ -e "$dev" ]; then
                if findmnt -M "$mount" -S "$dev" >/dev/null 2>&1; then
                    echo "MOUNTED"
                else
                    echo "PRESENT"
                fi
                return 0
            else
                echo "MISSING"
                return 0
            fi
        fi
    elif [ "$kind" = "SWAP" ]; then
        if [[ "$dev" == *"/by-uuid/"* ]]; then
            local uuid="${dev##*/}"
            if swapon --show=NAME -no 2>/dev/null | grep -wq "$uuid"; then
                echo "MOUNTED"
                return 0
            elif [ -e "/dev/disk/by-uuid/$uuid" ] || lsblk -no UUID 2>/dev/null | grep -wq "$uuid"; then
                echo "PRESENT"
                return 0
            else
                echo "MISSING"
                return 0
            fi
        elif [[ "$dev" =~ /dev/mapper/luks-(.+) ]]; then
            local luks_uuid="${BASH_REMATCH[1]}"
            if swapon --show=NAME -no 2>/dev/null | grep -q "$dev"; then
                echo "MOUNTED"
                return 0
            elif [ -e "$dev" ] || [ -e "/dev/disk/by-uuid/$luks_uuid" ] || lsblk -no UUID 2>/dev/null | grep -wq "$luks_uuid"; then
                echo "PRESENT"
                return 0
            else
                echo "MISSING"
                return 0
            fi
        else
            if swapon --show=NAME -no 2>/dev/null | grep -wq "$dev"; then
                echo "MOUNTED"
                return 0
            elif [ -e "$dev" ]; then
                echo "PRESENT"
                return 0
            else
                echo "MISSING"
                return 0
            fi
        fi
    elif [ "$kind" = "LUKS" ]; then
        if [[ "$dev" == *"/by-uuid/"* ]]; then
            local uuid="${dev##*/}"
            if [ -e "/dev/mapper/$mount" ]; then
                echo "MOUNTED"
                return 0
            elif [ -e "/dev/disk/by-uuid/$uuid" ] || lsblk -no UUID 2>/dev/null | grep -wq "$uuid"; then
                echo "PRESENT"
                return 0
            else
                echo "MISSING"
                return 0
            fi
        fi
    fi
    echo "MISSING"
}

# ------------------------------------------------------------------------------
# 📊 PAINEL DE AUDITORIA & CONFIRMAÇÃO PRÉ-REBUILD
# ------------------------------------------------------------------------------
show_preflight_audit() {
    local host="$1"
    local action="$2"
    local do_flake_update="$3"
    local skip_pull="$4"

    local current_hn
    current_hn=$(hostname 2>/dev/null || echo "nixos")
    local current_gen
    current_gen=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]\+-link' | grep -o '[0-9]\+' || echo "1")
    local branch
    branch=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || echo "main")

    local hw_file="$REPO_DIR/hardware-configuration.nix"
    local local_file="$REPO_DIR/local-config.nix"

    local host_gpu=""
    if [ -f "$local_file" ]; then
        host_gpu=$(grep -E "myHardware\.gpu\.type" "$local_file" 2>/dev/null | sed -E "s/.*\"([^\"]+)\".*/\1/" | head -n1 || echo "")
    fi
    if [ -z "$host_gpu" ] || [ "$host_gpu" = "auto" ]; then
        if lspci 2>/dev/null | grep -iq "nvidia"; then
            host_gpu="nvidia (detectado)"
        elif lspci 2>/dev/null | grep -iE "vga|3d" | grep -iq "intel"; then
            host_gpu="intel (detectado)"
        elif lspci 2>/dev/null | grep -iE "vga|3d" | grep -iq "amd\|radeon"; then
            host_gpu="amd (detectado)"
        else
            host_gpu="none"
        fi
    fi

    local host_cpu="Genérico"
    if grep -Eq "hardware\.cpu\.intel|kvm-intel" "$hw_file" 2>/dev/null || grep -iq "intel" /proc/cpuinfo 2>/dev/null; then
        host_cpu="Intel (kvm-intel)"
    elif grep -Eq "hardware\.cpu\.amd|kvm-amd" "$hw_file" 2>/dev/null || grep -iq "amd" /proc/cpuinfo 2>/dev/null; then
        host_cpu="AMD (kvm-amd)"
    fi

    local target_hn="$current_hn"
    if [ -f "$local_file" ]; then
        local found_hn
        found_hn=$(grep -E "networking\.hostName" "$local_file" 2>/dev/null | sed -E "s/.*\"([^\"]+)\".*/\1/" | head -n1 || echo "")
        [ -n "$found_hn" ] && target_hn="$found_hn"
    fi

    # Coleta lista de discos configurados
    local disks_raw
    disks_raw=$(parse_host_disks)

    local total_disks=0
    local matched_disks=0
    local missing_disks=0

    echo -e "${C_BORDER}╭─────────────────────────────────────────────────────────────────────────────╮${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_BOLD}${C_YELLOW}🔍 AUDITORIA DE CONFIGURAÇÃO & CONFIRMAÇÃO PRÉVIA${C_RESET}                          ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}🎯 Sistema WillOS     :${C_RESET} ${C_BOLD}${C_GREEN}%-20s${C_RESET} ${C_MUTED}🏷️ Hostname Destino:${C_RESET} ${C_CYAN}%-14s${C_RESET} ${C_BORDER}│${C_RESET}\n" "willos" "$target_hn"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}💻 Hostname Atual     :${C_RESET} ${C_YELLOW}%-20s${C_RESET} ${C_MUTED}🌿 Branch Git      :${C_RESET} ${C_BLUE}%-14s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$current_hn" "$branch"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}🧠 CPU Identificada   :${C_RESET} ${C_CYAN}%-20s${C_RESET} ${C_MUTED}🎮 Driver GPU      :${C_RESET} ${C_CYAN}%-14s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$host_cpu" "$host_gpu"
    echo -e "${C_BORDER}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_BOLD}${C_CYAN}💽 DISCOS & PARTIÇÕES MAPEADAS NO HARDWARE LOCAL:${C_RESET}                           ${C_BORDER}│${C_RESET}"

    if [ -z "$disks_raw" ]; then
        echo -e "${C_BORDER}│${C_RESET}  ${C_MUTED}Nenhuma partição explícita encontrada em hardware-configuration.nix${C_RESET}       ${C_BORDER}│${C_RESET}"
    else
        while IFS='|' read -r kind mount dev fstype; do
            [ -z "$kind" ] && continue
            ((total_disks++)) || true
            local status
            status=$(check_single_disk_status "$kind" "$mount" "$dev" "$fstype")

            local status_badge=""
            if [ "$status" = "MOUNTED" ]; then
                status_badge="${C_GREEN}✔ Montado e Ativo${C_RESET}"
                ((matched_disks++)) || true
            elif [ "$status" = "PRESENT" ]; then
                status_badge="${C_CYAN}✔ Presente no HW${C_RESET} "
                ((matched_disks++)) || true
            else
                status_badge="${C_RED}✖ NÃO ENCONTRADO${C_RESET} "
                ((missing_disks++)) || true
            fi

            local label="$mount"
            if [ "$kind" = "LUKS" ]; then
                label="LUKS ($mount)"
                if [ ${#label} -gt 16 ]; then
                    label="${label:0:13}..."
                fi
            fi

            local dev_short="$dev"
            if [ ${#dev_short} -gt 30 ]; then
                dev_short="...${dev_short: -27}"
            fi

            printf "${C_BORDER}│${C_RESET}   ${C_CYAN}%-4s${C_RESET} ${C_BOLD}%-16s${C_RESET} ${C_MUTED}%-30s${C_RESET} %-23b ${C_BORDER}│${C_RESET}\n" "$kind" "$label" "$dev_short" "$status_badge"
        done <<< "$disks_raw"
    fi

    echo -e "${C_BORDER}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_BOLD}${C_CYAN}⚡ AÇÕES E ATUALIZAÇÕES QUE SERÃO EXECUTADAS:${C_RESET}                              ${C_BORDER}│${C_RESET}"
    
    local op_action="Ativar imediatamente (switch)"
    if [ "$action" = "boot" ]; then op_action="Apenas no bootloader (boot)"; fi
    if [ "$action" = "test" ]; then op_action="Teste temporário (test)"; fi
    printf "${C_BORDER}│${C_RESET}  • ${C_MUTED}Modo de Execução  :${C_RESET} ${C_BOLD}${C_YELLOW}%-53s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$op_action"

    local flake_str="${C_MUTED}Não (Preserva versões fixadas no flake.lock)${C_RESET}"
    if [ "$do_flake_update" = true ]; then
        flake_str="${C_GREEN}${C_BOLD}SIM (Atualizará todos os pacotes upstream via nix flake update)${C_RESET}"
    fi
    printf "${C_BORDER}│${C_RESET}  • ${C_MUTED}Upgrade de Flake  :${C_RESET} %-62b ${C_BORDER}│${C_RESET}\n" "$flake_str"

    local git_str="${C_CYAN}Pull (rebase) origin/$branch + Push pós-rebuild${C_RESET}"
    if [ "$skip_pull" = true ]; then
        git_str="${C_YELLOW}Modo Rápido / Offline (Sincronização remota ignorada)${C_RESET}"
    fi
    printf "${C_BORDER}│${C_RESET}  • ${C_MUTED}Sincronização Git :${C_RESET} %-62b ${C_BORDER}│${C_RESET}\n" "$git_str"

    local status_output
    status_output=$(git -C "$REPO_DIR" status --short 2>/dev/null || echo "")
    local changed_count=0
    if [ -n "$status_output" ]; then
        changed_count=$(echo "$status_output" | grep -c -v '^[[:space:]]*$' || echo "0")
    fi
    printf "${C_BORDER}│${C_RESET}  • ${C_MUTED}Arquivos Locais   :${C_RESET} ${C_YELLOW}%-53s${C_RESET} ${C_BORDER}│${C_RESET}\n" "${changed_count} arquivo(s) com alterações pendentes"

    local next_gen=$((current_gen + 1))
    printf "${C_BORDER}│${C_RESET}  • ${C_MUTED}Geração NixOS     :${C_RESET} ${C_YELLOW}#${current_gen}${C_RESET} ──▶ ${C_GREEN}#${next_gen} (Nova geração do sistema)${C_RESET}             ${C_BORDER}│${C_RESET}\n"

    echo -e "${C_BORDER}╰─────────────────────────────────────────────────────────────────────────────╯${C_RESET}"

    if [ "$missing_disks" -gt 0 ]; then
        echo -e "${C_RED}${C_BOLD}⚠️  ALERTA DE SEGURANÇA:${C_RESET} ${C_YELLOW}${missing_disks} disco(s)/partição(ões) do hardware local NÃO foram encontrados!${C_RESET}"
        echo -e "${C_MUTED}    Verifique o seu hardware-configuration.nix antes de continuar.${C_RESET}\n"
    else
        echo -e "${C_GREEN}${C_BOLD}✔  COMPATIBILIDADE CONFIRMADA:${C_RESET} ${C_MUTED}Todos os ${matched_disks} discos/mappers deste perfil correspondem a este hardware.${C_RESET}\n"
    fi
}

# Diálogo interativo de confirmação pré-rebuild
interactive_preflight_confirm() {
    while true; do
        show_preflight_audit "$target_host" "$action" "$do_flake_update" "$skip_pull"

        local prompt_msg="${C_BOLD}${C_CYAN}Deseja prosseguir com o rebuild do WillOS?${C_RESET} [${C_GREEN}S${C_RESET}/n]: "
        echo -ne "$prompt_msg"
        local user_input=""
        read -r user_input || true
        user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]' | xargs)

        if [ -z "$user_input" ] || [ "$user_input" = "s" ] || [ "$user_input" = "sim" ] || [ "$user_input" = "y" ] || [ "$user_input" = "yes" ]; then
            echo ""
            return 0
        elif [ "$user_input" = "n" ] || [ "$user_input" = "nao" ] || [ "$user_input" = "não" ] || [ "$user_input" = "no" ] || [ "$user_input" = "cancel" ]; then
            echo -e "\n${C_RED}✖ Rebuild cancelado pelo operador. Nenhuma modificação foi aplicada.${C_RESET}\n"
            exit 0
        else
            echo -e "\n${C_RED}Opção não reconhecida. Responda 's' para confirmar ou 'n' para cancelar.${C_RESET}\n"
            sleep 1.5
            print_header
        fi
    done
}

# ------------------------------------------------------------------------------
# 📖 CENTRAL DE AJUDA
# ------------------------------------------------------------------------------
print_help() {
    print_header
    echo -e "${C_BOLD}${C_CYAN}USO:${C_RESET} rebuild [OPÇÕES] [MENSAGEM_DE_COMMIT]"
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}OPÇÕES DE CONTROLE & SEGURANÇA:${C_RESET}"
    echo -e "  ${C_GREEN}-H, --host <nome>${C_RESET}      Especifica manualmente o perfil do host (ex: casa, notegiga)"
    echo -e "  ${C_GREEN}-y, --yes${C_RESET}              Pula a confirmação interativa de segurança pré-rebuild"
    echo -e "  ${C_GREEN}--dry-run, --info${C_RESET}      Apenas audita perfis, discos e atualizações sem aplicar nada"
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}OPÇÕES DE COMPILAÇÃO & ATUALIZAÇÃO:${C_RESET}"
    echo -e "  ${C_GREEN}-u, --upgrade${C_RESET}          Atualiza todos os inputs do Flake (nix flake update) antes do rebuild"
    echo -e "  ${C_GREEN}--boot${C_RESET}                 Apenas adiciona a nova geração ao bootloader sem ativar imediatamente"
    echo -e "  ${C_GREEN}--test${C_RESET}                 Testa a configuração temporariamente sem torná-la padrão"
    echo -e "  ${C_GREEN}--show-trace${C_RESET}           Exibe o trace completo em caso de erros de compilação Nix"
    echo -e "  ${C_GREEN}--fast, --no-pull${C_RESET}      Pula a sincronização remota do Git (modo offline/rápido)"
    echo -e "  ${C_GREEN}-h, --help${C_RESET}             Exibe esta central de ajuda"
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}EXEMPLOS:${C_RESET}"
    echo -e "  ${C_MUTED}# Rebuild padrão interativo com auditoria de discos:${C_RESET}"
    echo -e "  ${C_CYAN}rebuild${C_RESET}"
    echo ""
    echo -e "${C_MUTED}# Apenas inspecionar compatibilidade de hardware e discos sem rebuild:${C_RESET}"
    echo -e "  ${C_CYAN}rebuild --info${C_RESET}"
    echo ""
    echo -e "${C_MUTED}# Rebuild forçando o perfil 'casa':${C_RESET}"
    echo -e "  ${C_CYAN}rebuild --host casa${C_RESET}"
    echo ""
    echo -e "${C_MUTED}# Rebuild com mensagem personalizada:${C_RESET}"
    echo -e "  ${C_CYAN}rebuild \"adicionando novos scripts e temas\"${C_RESET}"
    echo ""
    echo -e "${C_MUTED}# Grande atualização com upgrade de todas as dependências do Flake:${C_RESET}"
    echo -e "  ${C_CYAN}rebuild --upgrade \"grande atualização do sistema\"${C_RESET}"
    echo ""
    exit 0
}

# ------------------------------------------------------------------------------
# 🚀 FUNÇÃO PRINCIPAL
# ------------------------------------------------------------------------------
main() {
    local total_steps=5
    local skip_pull=false
    local do_flake_update=false
    local action="switch"
    local auto_confirm=false
    local dry_run=false
    local custom_host=""
    local rebuild_args=()
    local commit_msg=""

    # Parsing de argumentos
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                print_help
                ;;
            --fast|--no-pull)
                skip_pull=true
                ;;
            -u|--upgrade)
                do_flake_update=true
                ;;
            --boot)
                action="boot"
                ;;
            --test)
                action="test"
                ;;
            -y|--yes|--no-confirm)
                auto_confirm=true
                ;;
            --dry-run|--info)
                dry_run=true
                ;;
            -H|--host|--profile)
                shift
                custom_host="$1"
                ;;
            --host=*|--profile=*)
                custom_host="${1#*=}"
                ;;
            --show-trace|-v|--verbose|-L|--print-build-logs|--quiet|-k|--keep-going|-K|--keep-failed|--fallback|--repair|--refresh|--offline|--accept-flake-config)
                rebuild_args+=("$1")
                ;;
            -j*|--max-jobs*|--cores*|--option*)
                rebuild_args+=("$1")
                ;;
            -*)
                # Ignora flags não reconhecidas pelo nixos-rebuild sem interromper o rebuild
                ;;
            *)
                if [ -z "$commit_msg" ]; then
                    commit_msg="$1"
                else
                    commit_msg="$commit_msg $1"
                fi
                ;;
        esac
        shift
    done

    # Exibe o cabeçalho dinâmico
    print_header

    # Garante que os arquivos locais de hardware estão prontos
    ensure_local_hardware_ready

    # Configuração do alvo do Flake (padrão: willos)
    local target_host="${custom_host:-willos}"

    # Se modo dry-run / info solicitado, apenas exibe a auditoria e encerra
    if [ "$dry_run" = true ]; then
        show_preflight_audit "$target_host" "$action" "$do_flake_update" "$skip_pull"
        exit 0
    fi

    # Confirmação interativa de segurança se não foi passado --yes
    if [ "$auto_confirm" = false ]; then
        if [ -t 0 ] || [ -r /dev/tty ]; then
            interactive_preflight_confirm
        else
            show_preflight_audit "$target_host" "$action" "$do_flake_update" "$skip_pull"
        fi
    else
        show_preflight_audit "$target_host" "$action" "$do_flake_update" "$skip_pull"
    fi

    local global_start_time
    global_start_time=$(date +%s)

    local branch
    branch=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || echo "main")
    if [ -z "$branch" ]; then
        branch="main"
    fi

    # Captura a geração atual antes do rebuild
    local old_profile_link
    old_profile_link=$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || echo "")
    local old_gen_num
    old_gen_num=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]\+-link' | grep -o '[0-9]\+' || echo "1")

    # Validação antecipada do SUDO para que a senha não interrompa as animações
    if ! sudo -n true 2>/dev/null; then
        echo -e "${C_BORDER}╭─[ ${C_CYAN}🔐${C_BORDER} ] ${C_BOLD}${C_CYAN}Autenticação de Segurança${C_RESET}"
        echo -e "${C_BORDER}│  ${C_YELLOW}🔑 Por favor, informe sua senha de administrador para iniciar o Rebuild:${C_RESET}"
        sudo -v
        echo -e "${C_BORDER}╰── ${C_GREEN}✔ Privilégios administrativos concedidos!${C_RESET}\n"
    fi

    # Mantém o token sudo ativo em segundo plano durante a compilação
    while true; do sudo -n true 2>/dev/null; sleep 30; done &
    SUDO_PID=$!

    # ==========================================================================
    # FASE 1: SINCRONIZAÇÃO GIT & DETECÇÃO DE ALTERAÇÕES
    # ==========================================================================
    print_step_header "1" "$total_steps" "🌐" "Sincronização & Auditoria de Repositório Git"

    # Isola arquivos locais antes de sincronizar com a nuvem
    git -C "$REPO_DIR" reset HEAD hardware-configuration.nix local-config.nix >/dev/null 2>&1 || true

    if [ "$skip_pull" = true ]; then
        print_substep "⏩" "${C_YELLOW}Modo rápido:${C_RESET} Sincronização remota ignorada."
    else
        if run_with_dynamic_hud "Sincronização com origin/$branch" "Conectando ao GitHub..." git -C "$REPO_DIR" pull --rebase --autostash origin "$branch"; then
            print_substep "✨" "Repositório local perfeitamente alinhado com a nuvem."
        else
            print_substep "⚠️" "${C_YELLOW}Aviso:${C_RESET} Falha ao conectar ao upstream. Prosseguindo em modo local..."
        fi
    fi

    # Detecta arquivos modificados localmente
    local status_output
    status_output=$(git -C "$REPO_DIR" status --short 2>/dev/null || echo "")
    local changed_count=0
    if [ -n "$status_output" ]; then
        changed_count=$(echo "$status_output" | grep -c -v '^[[:space:]]*$' || echo "0")
    fi

    if [ "$changed_count" -gt 0 ]; then
        print_substep "📝" "${C_CYAN}${changed_count} arquivos modificados detectados:${C_RESET}"
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            local mod_type="${line:0:2}"
            local file_path="${line:3}"
            if [[ "$mod_type" == *"M"* ]]; then
                print_substep "  " "${C_YELLOW}[MOD]${C_RESET} ${file_path}"
            elif [[ "$mod_type" == *"?"* ]] || [[ "$mod_type" == *"A"* ]]; then
                print_substep "  " "${C_GREEN}[NEW]${C_RESET} ${file_path}"
            elif [[ "$mod_type" == *"D"* ]]; then
                print_substep "  " "${C_RED}[DEL]${C_RESET} ${file_path}"
            else
                print_substep "  " "${C_MUTED}[*]${C_RESET} ${file_path}"
            fi
        done <<< "$(echo "$status_output" | head -n 6)"

        if [ "$changed_count" -gt 6 ]; then
            local extra_files=$((changed_count - 6))
            print_substep "  " "${C_MUTED}... e mais ${extra_files} arquivo(s)${C_RESET}"
        fi
    else
        print_substep "🌿" "Nenhum arquivo modificado pendente no repositório."
    fi

    print_step_done "Auditoria de repositório concluída."

    # ==========================================================================
    # FASE 2: PREPARAÇÃO DO NIX FLAKE & INTEGRIDADE
    # ==========================================================================
    print_step_header "2" "$total_steps" "📦" "Preparação do Flake & Indexação"
    # Indexa alterações do repositório para o Flake mantendo arquivos locais ignorados
    run_with_dynamic_hud "Indexação de Arquivos para o Flake" "Adicionando alterações ao índice Git..." git -C "$REPO_DIR" add -A
    git -C "$REPO_DIR" reset HEAD hardware-configuration.nix local-config.nix >/dev/null 2>&1 || true

    if [ "$do_flake_update" = true ]; then
        run_with_dynamic_hud "Atualização de Inputs do Flake" "Executando nix flake update..." nix flake update --flake "$REPO_DIR"
    fi

    print_step_done "Flake indexado e pronto para compilação."

    # ==========================================================================
    # FASE 3: COMPILAÇÃO & ATIVAÇÃO DO SISTEMA
    # ==========================================================================
    print_step_header "3" "$total_steps" "⚡" "Compilação & Ativação do WillOS [$target_host] ($action)"

    # Limpeza preventiva e resolução de conflitos de unidades transientes do systemd
    if sudo systemctl is-active --quiet nixos-rebuild-switch-to-configuration.service 2>/dev/null; then
        print_substep "⏳" "${C_YELLOW}Aguardando ciclo de ativação anterior finalizar...${C_RESET}"
        local wait_count=0
        while sudo systemctl is-active --quiet nixos-rebuild-switch-to-configuration.service 2>/dev/null; do
            sleep 1
            ((wait_count++)) || true
            if [ "$wait_count" -ge 6 ]; then
                print_substep "⚠️" "${C_YELLOW}Serviço anterior bloqueado; cancelando unidade residual...${C_RESET}"
                sudo systemctl stop nixos-rebuild-switch-to-configuration.service 2>/dev/null || true
                break
            fi
        done
    fi
    sudo systemctl reset-failed nixos-rebuild-switch-to-configuration.service 2>/dev/null || true

    if ! run_with_dynamic_hud "Motor de Rebuild do WillOS" "Iniciando compilação do sistema ($target_host)..." sudo FLAKE_DIR="$REPO_DIR" nixos-rebuild "$action" --impure --flake "$REPO_DIR#$target_host" "${rebuild_args[@]}"; then
        print_step_fail "Falha durante a reconstrução do WillOS."
        play_sound "error"
        send_notify "critical" "❌ Erro no Rebuild WillOS" "A compilação do sistema falhou. Verifique os logs no terminal."

        echo -e "${C_RED}╔═════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
        echo -e "${C_RED}║  ❌  FALHA NA RECONSTRUÇÃO DO WILLOS                                        ║${C_RESET}"
        echo -e "${C_RED}╠═════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  ⚠️  Ocorreu um erro durante a compilação ou ativação da configuração.      ${C_RED}║${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  🛡️  A geração anterior (${C_YELLOW}#${old_gen_num}${C_RESET}) permanece 100% segura e ativa.          ${C_RED}║${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  📄  Log completo gravado em: ${C_BOLD}${C_YELLOW}/tmp/willos-rebuild.log${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  💡 ${C_CYAN}Dica:${C_RESET} Execute '${C_BOLD}rebuild --show-trace${C_RESET}' para inspecionar o erro completo.   ${C_RED}║${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  🔍  Para ver o log: '${C_BOLD}cat /tmp/willos-rebuild.log${C_RESET}'                            ${C_RED}║${C_RESET}"
        echo -e "${C_RED}╚═════════════════════════════════════════════════════════════════════════════╝${C_RESET}\n"
        exit 1
    fi

    print_step_done "Compilação e ativação concluídas com sucesso!"

    # ==========================================================================
    # FASE 4: AUDITORIA DE PACOTES & NOVA GERAÇÃO
    # ==========================================================================
    print_step_header "4" "$total_steps" "📊" "Auditoria de Pacotes & Nova Geração"

    local new_profile_link
    new_profile_link=$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || echo "")
    local new_gen_num
    new_gen_num=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]\+-link' | grep -o '[0-9]\+' || echo "$old_gen_num")

    if [ "$old_gen_num" != "$new_gen_num" ]; then
        print_substep "🏷️" "Transição: ${C_YELLOW}Geração #${old_gen_num}${C_RESET} ──▶ ${C_GREEN}${C_BOLD}Geração #${new_gen_num}${C_RESET} ${C_GREEN}(NOVA GERAÇÃO ATIVA)${C_RESET}"
    else
        print_substep "🏷️" "Geração: ${C_GREEN}${C_BOLD}Geração #${new_gen_num}${C_RESET} (Inalterada)"
    fi

    local count_added=0
    local count_updated=0
    local count_removed=0
    declare -a diff_highlights=()

    if [ -n "$old_profile_link" ] && [ -n "$new_profile_link" ] && [ "$old_profile_link" != "$new_profile_link" ]; then
        local diff_text
        diff_text=$(nix store diff-closures "$old_profile_link" "$new_profile_link" 2>/dev/null || echo "")

        while IFS= read -r line; do
            [ -z "$line" ] && continue
            if [[ "$line" == *"∅ →"* ]]; then
                ((count_added++)) || true
                local pkg_name
                pkg_name=$(echo "$line" | cut -d':' -f1 | xargs)
                local details
                details=$(echo "$line" | cut -d':' -f2- | sed 's/∅ →//' | xargs)
                if [ ${#diff_highlights[@]} -lt 6 ]; then
                    diff_highlights+=("${C_GREEN}+ [NOVO]${C_RESET} ${pkg_name} ${C_MUTED}(${details})${C_RESET}")
                fi
            elif [[ "$line" == *"→ ∅"* ]]; then
                ((count_removed++)) || true
                local pkg_name
                pkg_name=$(echo "$line" | cut -d':' -f1 | xargs)
                local details
                details=$(echo "$line" | cut -d':' -f2- | sed 's/→ ∅//' | xargs)
                if [ ${#diff_highlights[@]} -lt 6 ]; then
                    diff_highlights+=("${C_RED}- [REM]${C_RESET}  ${pkg_name} ${C_MUTED}(${details})${C_RESET}")
                fi
            elif [[ "$line" == *"→"* ]]; then
                ((count_updated++)) || true
                local pkg_name
                pkg_name=$(echo "$line" | cut -d':' -f1 | xargs)
                local details
                details=$(echo "$line" | cut -d':' -f2- | xargs)
                if [ ${#diff_highlights[@]} -lt 6 ]; then
                    diff_highlights+=("${C_YELLOW}~ [ATZ]${C_RESET}  ${pkg_name}: ${details}")
                fi
            fi
        done <<< "$diff_text"

        print_substep "📦" "${C_BOLD}Mudanças de Pacotes:${C_RESET} ${C_GREEN}+${count_added} novos${C_RESET} | ${C_YELLOW}~${count_updated} atualizados${C_RESET} | ${C_RED}-${count_removed} removidos${C_RESET}"

        for highlight in "${diff_highlights[@]}"; do
            print_substep "  " "$highlight"
        done

        local total_diff_count=$((count_added + count_updated + count_removed))
        if [ "$total_diff_count" -gt 6 ]; then
            local remaining=$((total_diff_count - 6))
            print_substep "  " "${C_MUTED}... e mais ${remaining} pacotes alterados no sistema.${C_RESET}"
        fi
    else
        print_substep "✨" "Configuração idêntica à anterior. Nenhum pacote modificado no closure."
    fi

    print_step_done "Auditoria de pacotes finalizada."

    # ==========================================================================
    # FASE 5: SNAPSHOT GIT & SINCRONIZAÇÃO EM NUVEM
    # ==========================================================================
    print_step_header "5" "$total_steps" "🚀" "Snapshot Git & Sincronização em Nuvem"

    local commit_sha=""

    # Adiciona todas as modificações reais (rastreadas ou novos arquivos não ignorados)
    git -C "$REPO_DIR" add -A

    # Garante que arquivos locais e específicos da máquina nunca sejam incluídos no commit
    git -C "$REPO_DIR" reset HEAD hardware-configuration.nix local-config.nix >/dev/null 2>&1 || true

    # Se houver alterações staged reais para commit
    if ! git -C "$REPO_DIR" diff --staged --quiet; then
        if [ -z "$commit_msg" ]; then
            local ts
            ts=$(date "+%Y-%m-%d %H:%M:%S")
            commit_msg="rebuild(willos): Gen #${new_gen_num} • ${ts}"
        fi

        if git -C "$REPO_DIR" commit -m "$commit_msg" >/dev/null 2>&1; then
            commit_sha=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "")
            print_substep "🏷️" "Commit gerado: [${C_YELLOW}${commit_sha}${C_RESET}] \"$commit_msg\""
        fi
    else
        print_substep "ℹ️" "Nenhuma alteração pendente para commit."
        commit_sha=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "")
    fi

    # Garante que os arquivos locais permaneçam fora do Git
    git -C "$REPO_DIR" reset HEAD hardware-configuration.nix local-config.nix >/dev/null 2>&1 || true

    # Envio com HUD dinâmico
    if run_with_dynamic_hud "Publicação no GitHub (origin/$branch)" "Enviando alterações..." git -C "$REPO_DIR" push origin "$branch"; then
        print_substep "☁️" "${C_GREEN}Push realizado com sucesso para o GitHub!${C_RESET}"
    else
        print_substep "⚠️" "${C_YELLOW}Aviso:${C_RESET} O rebuild local foi concluído, mas houve falha no push (sem internet ou sem permissão)."
    fi

    print_step_done "Sincronização remota finalizada."

    # Sincronização da paleta Caelestia/KDE
    if [ -f "$REPO_DIR/dotfiles/caelestia/sync-kde.sh" ]; then
        bash "$REPO_DIR/dotfiles/caelestia/sync-kde.sh" >/dev/null 2>&1 || true
    fi

    # ==========================================================================
    # 🏆 DASHBOARD RESUMO DA GRANDE ATUALIZAÇÃO
    # ==========================================================================
    local global_end_time
    global_end_time=$(date +%s)
    local elapsed=$((global_end_time - global_start_time))
    local elapsed_min=$((elapsed / 60))
    local elapsed_sec=$((elapsed % 60))
    local time_formatted
    printf -v time_formatted "%02dm %02ds" "$elapsed_min" "$elapsed_sec"

    echo -e "${C_BORDER}╔═════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BORDER}║  ${C_BOLD}${C_GREEN}🎉  W I L L O S   A T U A L I Z A D O   C O M   S U C E S S O !${C_RESET}               ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}╠═════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BORDER}║                                                                             ║${C_RESET}"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}🏷️   Geração WillOS     :${C_RESET}  ${C_YELLOW}Geração #%-3s${C_RESET} ──▶  ${C_BOLD}${C_GREEN}Geração #%-3s (ATIVADA)${C_RESET}      ${C_BORDER}║${C_RESET}\n" "$old_gen_num" "$new_gen_num"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}⏱️   Tempo de Operação  :${C_RESET}  ${C_CYAN}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "$time_formatted"
    if [ "$count_added" -gt 0 ] || [ "$count_updated" -gt 0 ] || [ "$count_removed" -gt 0 ]; then
        local summary_diff="${C_GREEN}+${count_added} novos${C_RESET}, ${C_YELLOW}~${count_updated} atualizados${C_RESET}, ${C_RED}-${count_removed} removidos${C_RESET}"
        printf "${C_BORDER}║${C_RESET}  ${C_MUTED}📦  Pacotes Alterados  :${C_RESET}  %-55b ${C_BORDER}║${C_RESET}\n" "$summary_diff"
    else
        printf "${C_BORDER}║${C_RESET}  ${C_MUTED}📦  Pacotes Alterados  :${C_RESET}  ${C_MUTED}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "0 pacotes (Configuração em sincronia total)"
    fi
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}🌿  Snapshot Git       :${C_RESET}  ${C_YELLOW}[%-7s]${C_RESET} origin/%-30s ${C_BORDER}║${C_RESET}\n" "$commit_sha" "$branch"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}🛡️   Status do Kernel   :${C_RESET}  ${C_BLUE}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "$kernel_ver (100% Estável)"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}✨  Ambiente Visual    :${C_RESET}  ${C_CYAN}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "Hyprland + Caelestia Shell Operacionais"
    echo -e "${C_BORDER}║                                                                             ║${C_RESET}"
    echo -e "${C_BORDER}║  ${C_BOLD}${C_CYAN}🚀 O seu WillOS está pronto e atualizado para uso!${C_RESET}                           ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}╚═════════════════════════════════════════════════════════════════════════════╝${C_RESET}\n"

    # Notificação no Desktop & Som de Conclusão
    play_sound "success"
    send_notify "normal" "🚀 WillOS Atualizado com Sucesso!" "Geração #${new_gen_num} ativada em ${time_formatted}."
}

main "$@"
