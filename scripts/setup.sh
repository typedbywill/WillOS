#!/usr/bin/env bash
# ==============================================================================
#  ⚡ WILLOS - UNIVERSAL SETUP & INSTALLATION ENGINE ⚡
#  Protocolo de Inicialização e Instalação Automatizada J.A.R.V.I.S.
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

# Cores ANSI padrão
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

# ------------------------------------------------------------------------------
# 🌐 VARIÁVEIS GLOBAIS E AMBIENTE
# ------------------------------------------------------------------------------
REPO_URL="https://github.com/typedbywill/myNix.git"
TARGET_DIR="${TARGET_DIR:-$HOME/nixos-hyprland-caelestia}"
SUDO_PID=""

# ------------------------------------------------------------------------------
# 🛡️ LIMPEZA E TRAPS (Ctrl+C / EXIT)
# ------------------------------------------------------------------------------
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

    if [ -n "$sound_file" ] && [ -f "$sound_file" ]; then
        if command -v pw-play >/dev/null 2>&1; then
            pw-play "$sound_file" >/dev/null 2>&1 &
        elif command -v paplay >/dev/null 2>&1; then
            paplay "$sound_file" >/dev/null 2>&1 &
        elif command -v aplay >/dev/null 2>&1; then
            aplay -q "$sound_file" >/dev/null 2>&1 &
        fi
    fi
}

send_notify() {
    local urgency="$1"
    local title="$2"
    local body="$3"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -a "J.A.R.V.I.S. Setup Core" -i "system-software-update" "$title" "$body" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 🤖 DIÁLOGO & INTERFACE J.A.R.V.I.S.
# ------------------------------------------------------------------------------
jarvis_speak() {
    local text="$1"
    echo -e "${C_BORDER}│  ${C_BOLD}${C_CYAN}🤖 [J.A.R.V.I.S.]:${C_RESET} ${C_ITALIC}\"${text}\"${C_RESET}"
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
# 🔧 HELPERS DE BOOTSTRAP RESILIENTES (Git, PCI, Nix)
# ------------------------------------------------------------------------------
run_git() {
    if command -v git >/dev/null 2>&1; then
        git "$@"
    elif command -v nix-shell >/dev/null 2>&1; then
        nix-shell -p git --run "git $(printf '%q ' "$@")"
    else
        echo -e "${C_RED}✖ Erro crítico: git não está disponível no sistema nem via nix-shell.${C_RESET}" >&2
        return 1
    fi
}

run_lspci() {
    if command -v lspci >/dev/null 2>&1; then
        lspci "$@"
    elif command -v nix-shell >/dev/null 2>&1; then
        nix-shell -p pciutils --run "lspci $(printf '%q ' "$@")" 2>/dev/null || true
    else
        echo ""
    fi
}

# ------------------------------------------------------------------------------
# 💻 CABEÇALHO CYBERPUNK & TELEMETRIA J.A.R.V.I.S.
# ------------------------------------------------------------------------------
print_header() {
    local host_name
    host_name=$(hostname 2>/dev/null || echo "nixos")
    local kernel_ver
    kernel_ver=$(uname -r 2>/dev/null || echo "Linux")
    local arch_name
    arch_name=$(uname -m 2>/dev/null || echo "x86_64")
    local current_gen
    current_gen=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]\+-link' | grep -o '[0-9]\+' || echo "1")
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
    echo -e "${C_BORDER}│${C_RESET}     ${C_BOLD}${C_BLUE}🤖  J . A . R . V . I . S .   O S   D E P L O Y M E N T   C O R E  🤖${C_RESET}     ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}       ${C_BOLD}${C_CYAN}⚡  W I L L O S   U N I V E R S A L   I N S T A L L E R   v 2 . 0  ⚡${C_RESET}       ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}💻 Host:${C_RESET}     ${C_BOLD}%-15s${C_RESET} ${C_MUTED}🐧 Kernel:${C_RESET} ${C_CYAN}%-15s${C_RESET}  ${C_MUTED}🏷️  Geração:${C_RESET}   ${C_YELLOW}#%-9s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$host_name" "$kernel_ver" "$current_gen"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}👤 Operador:${C_RESET} ${C_GREEN}%-15s${C_RESET} ${C_MUTED}📅 Data:${C_RESET}   ${C_MUTED}%-15s${C_RESET}  ${C_MUTED}🌐 Protocolo:${C_RESET} ${C_MAGENTA}%-11s${C_RESET} ${C_BORDER}│${C_RESET}\n" "${USER:-william}" "$now_str" "Nix Flakes"
    echo -e "${C_BORDER}╰─────────────────────────────────────────────────────────────────────────────╯${C_RESET}"
    echo ""
}

# ------------------------------------------------------------------------------
# 🌀 MOTOR DE EXECUÇÃO COM HUD DINÂMICO & SPINNER EM TEMPO REAL
# ------------------------------------------------------------------------------
run_with_dynamic_hud() {
    local title="$1"
    local default_status="$2"
    shift 2

    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local spin_colors=("$C_CYAN" "$C_BLUE" "$C_WHITE" "$C_GREEN")
    
    local logfile
    logfile=$(mktemp /tmp/willos_setup_task.XXXXXX)

    # Executa os argumentos via bash garantindo compatibilidade com funções ou pipelines
    if [ "$#" -eq 1 ]; then
        bash -c "$1" > "$logfile" 2>&1 &
    else
        "$@" > "$logfile" 2>&1 &
    fi
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
                status_line="🚀 Ativando serviços e profile WillOS..."
            elif [[ "$raw_last" =~ reloading|restarting ]]; then
                status_line="🔄 Recarregando daemons de sistema..."
            elif [[ "$raw_last" =~ eval ]]; then
                status_line="🧠 Avaliando expressões Flake e dependências..."
            elif [[ "$raw_last" =~ Cloning|Clonando ]]; then
                status_line="📦 Baixando repositório WillOS do GitHub..."
            elif [[ "$raw_last" =~ Receiving|Resolving|Compressing ]]; then
                status_line="📡 Transferindo objetos e deltas Git..."
            elif [ -n "$raw_last" ]; then
                status_line="$(echo "$raw_last" | cut -c1-55)"
            fi
        fi

        # Barra de pulso animada Sci-Fi
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
            printf "\r\033[K${C_BORDER}│  ${C_BORDER}├─ [${C_CYAN}%s${C_BORDER}] ${C_YELLOW}J.A.R.V.I.S. EM AÇÃO${C_RESET}\n" "$bar"
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
        printf "\r\033[K${C_BORDER}│  ${C_RED}✖${C_RESET} ${C_BOLD}${title}${C_RESET} ${C_RED}falhou após %02dm %02ds (Código: ${exit_code})!${C_RESET}\n\n" "$min_tot" "$sec_tot"
        echo -e "${C_RED}─────── [ RELATÓRIO DE ERRO J.A.R.V.I.S. ] ───────${C_RESET}"
        tail -n 35 "$logfile" 2>/dev/null || echo "Nenhum log gravado."
        echo -e "${C_RED}───────────────────────────────────────────────────${C_RESET}\n"
        rm -f "$logfile"
        return "$exit_code"
    fi
}

# ------------------------------------------------------------------------------
# 🔍 DETECTORES DE HARDWARE INTELIGENTES
# ------------------------------------------------------------------------------
detect_cpu_info() {
    local cpu_name=""
    if [ -f /proc/cpuinfo ]; then
        cpu_name=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | xargs || echo "")
    fi
    if [ -z "$cpu_name" ] && command -v lscpu >/dev/null 2>&1; then
        cpu_name=$(lscpu 2>/dev/null | grep -m1 "Model name" | cut -d':' -f2 | xargs || echo "")
    fi
    if [ -z "$cpu_name" ]; then
        cpu_name="Processador x86_64 Genérico"
    fi

    local cores
    cores=$(nproc 2>/dev/null || echo "1")
    echo "${cpu_name} (${cores} threads)"
}

detect_gpu_type() {
    local pci_out
    pci_out=$(run_lspci 2>/dev/null || echo "")

    local has_nvidia=false
    local has_intel=false
    local has_amd=false

    if echo "$pci_out" | grep -iqE "nvidia|geforce|quadro|rtx|gtx"; then
        has_nvidia=true
    fi
    if echo "$pci_out" | grep -iE "vga|3d|display" | grep -iq "intel"; then
        has_intel=true
    fi
    if echo "$pci_out" | grep -iE "vga|3d|display" | grep -iqE "amd|radeon|advanced micro devices"; then
        has_amd=true
    fi

    if [ "$has_nvidia" = true ] && [ "$has_intel" = true ]; then
        echo "hybrid-intel-nvidia"
    elif [ "$has_nvidia" = true ]; then
        echo "nvidia"
    elif [ "$has_amd" = true ]; then
        echo "amd"
    elif [ "$has_intel" = true ]; then
        echo "intel"
    else
        echo "none"
    fi
}

detect_ram_info() {
    if [ -f /proc/meminfo ]; then
        local mem_kb
        mem_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
        if [ "$mem_kb" -gt 0 ] 2>/dev/null; then
            local mem_gb=$(( (mem_kb + 524288) / 1048576 ))
            echo "${mem_gb} GB RAM"
            return 0
        fi
    fi
    if command -v free >/dev/null 2>&1; then
        local free_out
        free_out=$(free -h 2>/dev/null | awk '/^Mem/ {print $2}' || echo "")
        if [ -n "$free_out" ]; then
            echo "${free_out} RAM"
            return 0
        fi
    fi
    echo "16 GB RAM"
}

parse_host_disks() {
    local hw_file="$TARGET_DIR/hardware-configuration.nix"
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
# 📊 PAINEL DE AUDITORIA & CONFIRMAÇÃO PRÉ-INSTALAÇÃO J.A.R.V.I.S.
# ------------------------------------------------------------------------------
show_preflight_audit() {
    local target_host="$1"
    local target_gpu="$2"
    local target_dir="$3"
    local action="$4"

    local current_hn
    current_hn=$(hostname 2>/dev/null || echo "nixos")
    local cpu_info
    cpu_info=$(detect_cpu_info)
    if [ ${#cpu_info} -gt 50 ]; then
        cpu_info="${cpu_info:0:47}..."
    fi
    local ram_info
    ram_info=$(detect_ram_info)
    local disks_raw
    disks_raw=$(parse_host_disks)

    local target_dir_short="$target_dir"
    if [ ${#target_dir_short} -gt 20 ]; then
        target_dir_short="...${target_dir_short: -17}"
    fi

    echo -e "${C_BORDER}╭─────────────────────────────────────────────────────────────────────────────╮${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_BOLD}${C_CYAN}🤖 DIAGNÓSTICO J.A.R.V.I.S. & AUDITORIA DE INSTALAÇÃO DO WILLOS${C_RESET}            ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}🎯 Sistema Alvo       :${C_RESET} ${C_BOLD}${C_GREEN}%-20s${C_RESET} ${C_MUTED}🏷️ Hostname Destino:${C_RESET} ${C_CYAN}%-14s${C_RESET} ${C_BORDER}│${C_RESET}\n" "willos" "$target_host"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}💻 Hostname Atual     :${C_RESET} ${C_YELLOW}%-20s${C_RESET} ${C_MUTED}📁 Pasta Destino   :${C_RESET} ${C_BLUE}%-14s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$current_hn" "$target_dir_short"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}🧠 Processador (CPU)  :${C_RESET} ${C_CYAN}%-53s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$cpu_info"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}🎮 Driver Gráfico GPU :${C_RESET} ${C_BOLD}${C_GREEN}%-20s${C_RESET} ${C_MUTED}💾 Memória RAM     :${C_RESET} ${C_MUTED}%-14s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$target_gpu" "$ram_info"
    echo -e "${C_BORDER}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_BOLD}${C_CYAN}💽 ARQUITETURA DE ARMAZENAMENTO MAPEADA NO HARDWARE LOCAL:${C_RESET}                  ${C_BORDER}│${C_RESET}"

    local total_disks=0
    local matched_disks=0
    local missing_disks=0

    if [ -z "$disks_raw" ]; then
        echo -e "${C_BORDER}│${C_RESET}  ${C_MUTED}Nenhum hardware-configuration.nix pré-existente (será gerado na Fase 3)${C_RESET}  ${C_BORDER}│${C_RESET}"
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
    echo -e "${C_BORDER}│${C_RESET}  ${C_BOLD}${C_CYAN}⚡ PLANO DE AÇÃO J.A.R.V.I.S.:${C_RESET}                                             ${C_BORDER}│${C_RESET}"
    printf "${C_BORDER}│${C_RESET}  • ${C_MUTED}Repositório Central:${C_RESET} %-54s ${C_BORDER}│${C_RESET}\n" "$REPO_URL"
    printf "${C_BORDER}│${C_RESET}  • ${C_MUTED}Destino do Código  :${C_RESET} %-54s ${C_BORDER}│${C_RESET}\n" "$target_dir"
    printf "${C_BORDER}│${C_RESET}  • ${C_MUTED}Modo de Aplicação  :${C_RESET} ${C_BOLD}${C_YELLOW}%-54s${C_RESET} ${C_BORDER}│${C_RESET}\n" "nixos-rebuild $action (switch imediato com Hyprland)"
    echo -e "${C_BORDER}╰─────────────────────────────────────────────────────────────────────────────╯${C_RESET}\n"
}

# Diálogo interativo de confirmação pré-instalação
interactive_preflight_confirm() {
    local target_host="$1"
    local target_gpu="$2"
    local target_dir="$3"
    local action="$4"

    while true; do
        show_preflight_audit "$target_host" "$target_gpu" "$target_dir" "$action"

        jarvis_speak "Chefe, todos os parâmetros foram calibrados. Posso iniciar a instalação do WillOS?"
        echo ""
        local prompt_msg="${C_BOLD}${C_CYAN}Deseja prosseguir com a instalação do WillOS?${C_RESET} [${C_GREEN}S${C_RESET}/n]: "
        echo -ne "$prompt_msg"

        local user_input=""
        if [ -r /dev/tty ]; then
            read -r user_input < /dev/tty || true
        else
            read -r user_input || true
        fi
        user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]' | xargs)

        if [ -z "$user_input" ] || [ "$user_input" = "s" ] || [ "$user_input" = "sim" ] || [ "$user_input" = "y" ] || [ "$user_input" = "yes" ]; then
            echo ""
            return 0
        elif [ "$user_input" = "n" ] || [ "$user_input" = "nao" ] || [ "$user_input" = "não" ] || [ "$user_input" = "no" ] || [ "$user_input" = "cancel" ]; then
            echo -e "\n${C_RED}✖ Instalação abortada pelo operador. Nenhum subsistema foi modificado.${C_RESET}\n"
            exit 0
        else
            echo -e "\n${C_RED}Opção não reconhecida. Digite 's' para confirmar ou 'n' para cancelar.${C_RESET}\n"
            sleep 1.5
            print_header
        fi
    done
}

# ------------------------------------------------------------------------------
# 📖 CENTRAL DE AJUDA J.A.R.V.I.S.
# ------------------------------------------------------------------------------
print_help() {
    print_header
    echo -e "${C_BOLD}${C_CYAN}USO:${C_RESET} setup.sh [OPÇÕES]"
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}OPÇÕES DE CONTROLE & AMBIENTE:${C_RESET}"
    echo -e "  ${C_GREEN}-y, --yes${C_RESET}              Pula a confirmação interativa e instala automaticamente"
    echo -e "  ${C_GREEN}--dry-run, --info${C_RESET}      Apenas audita o hardware e configurações sem aplicar nada"
    echo -e "  ${C_GREEN}--dir <caminho>${C_RESET}        Define o diretório de destino do repositório WillOS"
    echo -e "  ${C_GREEN}--hostname <nome>${C_RESET}      Especifica manualmente o nome do host (ex: willos, notegiga)"
    echo -e "  ${C_GREEN}--gpu <driver>${C_RESET}         Força o driver de vídeo: ${C_CYAN}intel${C_RESET}, ${C_CYAN}nvidia${C_RESET}, ${C_CYAN}hybrid-intel-nvidia${C_RESET}, ${C_CYAN}amd${C_RESET}, ${C_CYAN}none${C_RESET}"
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}OPÇÕES DE COMPILAÇÃO NIXOS:${C_RESET}"
    echo -e "  ${C_GREEN}--boot${C_RESET}                 Apenas adiciona a nova geração ao bootloader sem switch imediato"
    echo -e "  ${C_GREEN}--test${C_RESET}                 Testa a configuração temporariamente sem torná-la padrão"
    echo -e "  ${C_GREEN}--show-trace${C_RESET}           Exibe o trace detalhado em caso de erro na compilação Nix"
    echo -e "  ${C_GREEN}-h, --help${C_RESET}             Exibe esta central de ajuda J.A.R.V.I.S."
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}EXEMPLOS:${C_RESET}"
    echo -e "  ${C_MUTED}# Instalação padrão interativa assistida por J.A.R.V.I.S.:${C_RESET}"
    echo -e "  ${C_CYAN}./scripts/setup.sh${C_RESET}"
    echo ""
    echo -e "${C_MUTED}# Instalação automatizada direta sem confirmações:${C_RESET}"
    echo -e "  ${C_CYAN}./scripts/setup.sh -y${C_RESET}"
    echo ""
    echo -e "${C_MUTED}# Forçando driver híbrido Intel + NVIDIA:${C_RESET}"
    echo -e "  ${C_CYAN}./scripts/setup.sh --gpu hybrid-intel-nvidia${C_RESET}"
    echo ""
    exit 0
}

# ------------------------------------------------------------------------------
# 🚀 FUNÇÃO PRINCIPAL
# ------------------------------------------------------------------------------
main() {
    local total_steps=6
    local auto_confirm=false
    local dry_run=false
    local action="switch"
    local custom_hostname=""
    local custom_gpu=""
    local custom_dir=""
    local rebuild_extra_args=()

    # Parsing de argumentos
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                print_help
                ;;
            -y|--yes|--no-confirm)
                auto_confirm=true
                ;;
            --dry-run|--info)
                dry_run=true
                ;;
            --boot)
                action="boot"
                ;;
            --test)
                action="test"
                ;;
            --show-trace)
                rebuild_extra_args+=("--show-trace")
                ;;
            --dir)
                shift
                custom_dir="$1"
                ;;
            --dir=*)
                custom_dir="${1#*=}"
                ;;
            --hostname|--host)
                shift
                custom_hostname="$1"
                ;;
            --hostname=*|--host=*)
                custom_hostname="${1#*=}"
                ;;
            --gpu)
                shift
                custom_gpu="$1"
                ;;
            -u|--upgrade)
                # Flag de compatibilidade para atualização
                ;;
            -v|--verbose|-L|--print-build-logs|--quiet|-k|--keep-going|-K|--keep-failed|--fallback|--repair|--refresh|--offline|--accept-flake-config)
                rebuild_extra_args+=("$1")
                ;;
            -j*|--max-jobs*|--cores*|--option*)
                rebuild_extra_args+=("$1")
                ;;
            -*)
                # Ignora flags desconhecidas com segurança sem repassar ao nixos-rebuild
                ;;
            *)
                ;;
        esac
        shift
    done

    if [ -n "$custom_dir" ]; then
        TARGET_DIR="$custom_dir"
    fi

    # Exibe cabeçalho Sci-Fi
    print_header

    local global_start_time
    global_start_time=$(date +%s)

    # Detecção inteligente de Hardware
    local detected_gpu
    detected_gpu=$(detect_gpu_type)
    local target_gpu="${custom_gpu:-$detected_gpu}"

    local detected_hn
    detected_hn=$(hostname 2>/dev/null || echo "")
    if [ -z "$detected_hn" ] || [ "$detected_hn" = "nixos" ]; then
        detected_hn="willos"
    fi
    local target_hn="${custom_hostname:-$detected_hn}"

    # Se modo dry-run solicitado
    if [ "$dry_run" = true ]; then
        show_preflight_audit "$target_hn" "$target_gpu" "$TARGET_DIR" "$action"
        jarvis_speak "Modo de auditoria concluído. Nenhum arquivo foi alterado, Chefe."
        exit 0
    fi

    # Confirmação interativa pré-instalação
    if [ "$auto_confirm" = false ]; then
        interactive_preflight_confirm "$target_hn" "$target_gpu" "$TARGET_DIR" "$action"
    else
        show_preflight_audit "$target_hn" "$target_gpu" "$TARGET_DIR" "$action"
    fi

    # ==========================================================================
    # FASE 1: DIAGNÓSTICO DO HOST & SENSORES DE AMBIENTE
    # ==========================================================================
    print_step_header "1" "$total_steps" "🛰️" "Diagnóstico do Host & Sensores de Ambiente"
    jarvis_speak "Verificando permissões de segurança e integridade das ferramentas básicas..."

    # Validação antecipada de SUDO
    if ! sudo -n true 2>/dev/null; then
        echo -e "${C_BORDER}│  ${C_YELLOW}🔑 Por favor, autentique com sua senha de administrador para iniciar o Setup:${C_RESET}"
        sudo -v
        print_substep "🔐" "${C_GREEN}Privilégios administrativos concedidos com sucesso.${C_RESET}"
    else
        print_substep "🔐" "${C_GREEN}Privilégios administrativos ativos.${C_RESET}"
    fi

    # Mantém o token sudo ativo em segundo plano
    while true; do sudo -n true 2>/dev/null; sleep 30; done &
    SUDO_PID=$!

    # Verificação de ferramentas essenciais
    if command -v nix >/dev/null 2>&1; then
        print_substep "❄️" "Nix Package Manager: ${C_GREEN}Detectado e Operacional${C_RESET}"
    else
        print_substep "⚠️" "${C_YELLOW}Aviso:${C_RESET} Nix não encontrado no PATH imediato."
    fi

    if command -v git >/dev/null 2>&1; then
        print_substep "📦" "Git Engine: ${C_GREEN}Disponível no sistema${C_RESET}"
    else
        print_substep "⚡" "Git Engine: ${C_CYAN}Ambiente sob demanda via nix-shell pronto para uso${C_RESET}"
    fi

    print_step_done "Diagnóstico inicial de sensores aprovado."

    # ==========================================================================
    # FASE 2: DOWNLOAD & SINCRONIZAÇÃO DO REPOSITÓRIO WILLOS
    # ==========================================================================
    print_step_header "2" "$total_steps" "📦" "Download & Sincronização do Núcleo WillOS"
    jarvis_speak "Conectando ao repositório central e estabelecendo cópia local em ${TARGET_DIR}..."

    mkdir -p "$(dirname "$TARGET_DIR")"

    if [ -d "$TARGET_DIR/.git" ]; then
        print_substep "📁" "Repositório existente detectado em ${C_CYAN}${TARGET_DIR}${C_RESET}."
        if run_with_dynamic_hud "Sincronização com origin/main" "Atualizando código-fonte do WillOS..." run_git -C "$TARGET_DIR" pull --ff-only origin main; then
            print_substep "✨" "Repositório sincronizado com as últimas melhorias."
        else
            print_substep "ℹ️" "Mantendo versão local pré-existente do repositório."
        fi
    else
        if run_with_dynamic_hud "Download do Repositório WillOS" "Clonando ${REPO_URL}..." run_git clone "$REPO_URL" "$TARGET_DIR"; then
            print_substep "✨" "Repositório clonado com sucesso para ${C_CYAN}${TARGET_DIR}${C_RESET}."
        else
            print_step_fail "Falha ao transferir o repositório central."
            play_sound "error"
            exit 1
        fi
    fi

    # Configura safe.directory no git para evitar alertas de permissão
    run_git config --global --add safe.directory "$TARGET_DIR" 2>/dev/null || true

    print_step_done "Código-fonte do WillOS pronto para inicialização."

    # ==========================================================================
    # FASE 3: MAPEAMENTO DE HARDWARE & DISCOS LOCAIS
    # ==========================================================================
    print_step_header "3" "$total_steps" "⚙️" "Mapeamento de Hardware & Discos Locais"
    jarvis_speak "Escaneando barramentos PCI, tabelas de partição e layout do hardware..."

    local hw_target="$TARGET_DIR/hardware-configuration.nix"
    if [ ! -f "$hw_target" ]; then
        if [ -f "/etc/nixos/hardware-configuration.nix" ]; then
            print_substep "📋" "Importando hardware-configuration.nix de /etc/nixos/..."
            cp "/etc/nixos/hardware-configuration.nix" "$hw_target"
            print_substep "✔" "Arquivo de hardware importado com sucesso."
        else
            print_substep "⚙️" "Sintetizando nova configuração de hardware via nixos-generate-config..."
            if command -v nixos-generate-config >/dev/null 2>&1; then
                nixos-generate-config --show-hardware-config > "$hw_target" 2>/dev/null || sudo nixos-generate-config --show-hardware-config > "$hw_target"
            else
                sudo nixos-generate-config --show-hardware-config > "$hw_target"
            fi
            print_substep "✔" "Configuração de hardware gerada com base nos sensores locais."
        fi
    else
        print_substep "✔" "hardware-configuration.nix local já configurado e preservado."
    fi

    # Isola o hardware local do controle de versão
    run_git -C "$TARGET_DIR" reset HEAD hardware-configuration.nix >/dev/null 2>&1 || true

    print_step_done "Mapeamento de hardware concluído."

    # ==========================================================================
    # FASE 4: SÍNTESE DA MATRIZ DE CONFIGURAÇÃO LOCAL
    # ==========================================================================
    print_step_header "4" "$total_steps" "🧠" "Síntese da Matriz de Configuração Local"
    jarvis_speak "Configurando módulos de GPU (${target_gpu}) e identidade de rede (${target_hn})..."

    local local_target="$TARGET_DIR/local-config.nix"
    if [ ! -f "$local_target" ] || [ -n "$custom_gpu" ] || [ -n "$custom_hostname" ]; then
        cat <<EOF > "$local_target"
# ==============================================================================
# 🛠️ WillOS - Configuração Local da Máquina
# Gerado e calibrado automaticamente pelo assistente J.A.R.V.I.S.
# ==============================================================================
{ lib, ... }:

{
  networking.hostName = "${target_hn}";
  myHardware.gpu.type = "${target_gpu}";
}
EOF
        print_substep "✨" "Matriz local criada em ${C_CYAN}local-config.nix${C_RESET} [GPU: ${C_GREEN}${target_gpu}${C_RESET}, Host: ${C_GREEN}${target_hn}${C_RESET}]."
    else
        print_substep "✔" "local-config.nix já existente (preservando opções previamente configuradas)."
    fi

    # Mantém local-config fora do Git
    run_git -C "$TARGET_DIR" reset HEAD local-config.nix >/dev/null 2>&1 || true

    print_step_done "Matriz de personalização local sintetizada."

    # ==========================================================================
    # FASE 5: COMPILAÇÃO & ATIVAÇÃO DO SISTEMA WILLOS
    # ==========================================================================
    print_step_header "5" "$total_steps" "⚡" "Compilação & Ativação do Sistema WillOS"
    jarvis_speak "Engajando motor de compilação NixOS Flake. Construindo ambiente completo..."

    # Limpeza preventiva de possíveis unidades de rebuild bloqueadas
    if sudo systemctl is-active --quiet nixos-rebuild-switch-to-configuration.service 2>/dev/null; then
        print_substep "⏳" "${C_YELLOW}Aguardando ciclo de ativação anterior finalizar...${C_RESET}"
        sudo systemctl stop nixos-rebuild-switch-to-configuration.service 2>/dev/null || true
    fi
    sudo systemctl reset-failed nixos-rebuild-switch-to-configuration.service 2>/dev/null || true

    # Indexa arquivos necessários para o Nix Flake
    run_git -C "$TARGET_DIR" add -A >/dev/null 2>&1 || true
    run_git -C "$TARGET_DIR" reset HEAD hardware-configuration.nix local-config.nix >/dev/null 2>&1 || true

    # Monta comando de rebuild
    local rebuild_cmd=""
    if command -v git >/dev/null 2>&1; then
        rebuild_cmd="sudo env PATH=\"$PATH\" FLAKE_DIR=\"$TARGET_DIR\" nixos-rebuild $action --impure --flake \"$TARGET_DIR#willos\" $(printf '%q ' "${rebuild_extra_args[@]}")"
    else
        rebuild_cmd="nix-shell -p git --run \"sudo env PATH=\\\"\\\$PATH\\\" FLAKE_DIR=\\\"$TARGET_DIR\\\" nixos-rebuild $action --impure --flake \\\"$TARGET_DIR#willos\\\" $(printf '%q ' "${rebuild_extra_args[@]}")\""
    fi

    if ! run_with_dynamic_hud "Motor de Instalação WillOS" "Iniciando compilação do sistema..." "$rebuild_cmd"; then
        print_step_fail "Falha durante a instalação do WillOS."
        play_sound "error"
        send_notify "critical" "❌ Falha no Setup WillOS" "A instalação do sistema foi interrompida. Verifique os logs no terminal."

        echo -e "${C_RED}╔═════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
        echo -e "${C_RED}║  ❌  FALHA NA INICIALIZAÇÃO DO WILLOS                                       ║${C_RESET}"
        echo -e "${C_RED}╠═════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  ⚠️  Ocorreu um erro durante a compilação ou ativação da configuração.      ${C_RED}║${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  💡 ${C_CYAN}Dica J.A.R.V.I.S.:${C_RESET} Execute com '${C_BOLD}--show-trace${C_RESET}' para inspecionar o erro.     ${C_RED}║${C_RESET}"
        echo -e "${C_RED}╚═════════════════════════════════════════════════════════════════════════════╝${C_RESET}\n"
        exit 1
    fi

    print_step_done "Compilação e ativação do sistema concluídas com êxito!"

    # ==========================================================================
    # FASE 6: CALIBRAÇÃO DE AMBIENTE & INTEGRAÇÃO CAELESTIA
    # ==========================================================================
    print_step_header "6" "$total_steps" "🚀" "Calibração de Ambiente & Integração Caelestia"
    jarvis_speak "Calibrando integração com o desktop, paleta Caelestia e atalhos de controle..."

    # Garante isolamento Git
    run_git -C "$TARGET_DIR" reset HEAD hardware-configuration.nix local-config.nix >/dev/null 2>&1 || true

    # Sincronização de paleta KDE/Caelestia se disponível
    if [ -f "$TARGET_DIR/dotfiles/caelestia/sync-kde.sh" ]; then
        print_substep "🎨" "Sincronizando paleta e temas visuais do Caelestia..."
        bash "$TARGET_DIR/dotfiles/caelestia/sync-kde.sh" >/dev/null 2>&1 || true
    fi

    # Identifica a nova geração ativada
    local current_gen
    current_gen=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]\+-link' | grep -o '[0-9]\+' || echo "1")

    print_step_done "Todos os subsistemas calibrados e prontos para uso."

    # ==========================================================================
    # 🏆 DASHBOARD RESUMO J.A.R.V.I.S.
    # ==========================================================================
    local global_end_time
    global_end_time=$(date +%s)
    local elapsed=$((global_end_time - global_start_time))
    local elapsed_min=$((elapsed / 60))
    local elapsed_sec=$((elapsed % 60))
    local time_formatted
    printf -v time_formatted "%02dm %02ds" "$elapsed_min" "$elapsed_sec"

    echo -e "${C_BORDER}╔═════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BORDER}║  ${C_BOLD}${C_GREEN}🎉  W I L L O S   I N S T A L A D O   C O M   S U C E S S O !${C_RESET}                 ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}╠═════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BORDER}║                                                                             ║${C_RESET}"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}🏷️   Geração WillOS     :${C_RESET}  ${C_BOLD}${C_GREEN}Geração #%-3s (SISTEMA ATIVO)${C_RESET}                          ${C_BORDER}║${C_RESET}\n" "$current_gen"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}⏱️   Tempo de Instalação:${C_RESET}  ${C_CYAN}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "$time_formatted"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}🎮  Driver Gráfico     :${C_RESET}  ${C_GREEN}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "$target_gpu (Ativo e Configurado)"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}💻  Identidade da Rede :${C_RESET}  ${C_YELLOW}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "Hostname: $target_hn"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}📁  Repositório Local  :${C_RESET}  ${C_BLUE}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "$TARGET_DIR"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}✨  Ambiente Gráfico   :${C_RESET}  ${C_CYAN}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "Hyprland + Caelestia Shell Operacionais"
    echo -e "${C_BORDER}║                                                                             ║${C_RESET}"
    echo -e "${C_BORDER}╠─────────────────────────────────────────────────────────────────────────────╣${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET}  ${C_BOLD}${C_CYAN}💡 COMANDOS ÚTEIS & ATALHOS DO WILLOS:${C_RESET}                                     ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET}  • ${C_YELLOW}rebuild${C_RESET}            : Reconstruir o sistema após alterar configurações    ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET}  • ${C_YELLOW}rebuild --upgrade${C_RESET}  : Atualizar todos os pacotes e inputs do Flake        ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET}  • ${C_CYAN}Super + Enter${C_RESET}      : Abrir Terminal Kitty                                ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET}  • ${C_CYAN}Super + Space${C_RESET}      : Abrir Launcher Fuzzel                               ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET}  • ${C_CYAN}Super + E${C_RESET}          : Abrir Gerenciador de Arquivos Dolphin               ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║                                                                             ║${C_RESET}"
    echo -e "${C_BORDER}║  ${C_BOLD}${C_CYAN}🤖 [J.A.R.V.I.S.]: Todos os sistemas operacionais, Chefe. Aproveite o WillOS!${C_RESET} ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}╚═════════════════════════════════════════════════════════════════════════════╝${C_RESET}\n"

    # Efeitos sonoros e notificação
    play_sound "success"
    send_notify "normal" "🚀 WillOS Instalado com Sucesso!" "Geração #${current_gen} ativada em ${time_formatted}. J.A.R.V.I.S. pronto para uso."
}

main "$@"
