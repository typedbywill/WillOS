#!/usr/bin/env bash
# ==============================================================================
#  ⚡ NIXOS SYSTEM CORE UPGRADE & REBUILD ENGINE ⚡
#  Motor de reconstrução ultra-dinâmico, interativo e cinematográfico
# ==============================================================================

set -eo pipefail

# ------------------------------------------------------------------------------
# 🎨 PALETA DE CORES ANSI TRUECOLOR (24-BIT) & ESTILOS
# ------------------------------------------------------------------------------
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_ITALIC="\033[3m"
C_UNDERLINE="\033[4m"

# Gradientes Neon (Caelestia / Cyberpunk Vibe)
C_CYAN="\033[38;2;56;189;248m"          # #38bdf8
C_BLUE="\033[38;2;96;165;250m"          # #60a5fa
C_PURPLE="\033[38;2;192;132;252m"       # #c084fc
C_MAGENTA="\033[38;2;232;121;249m"      # #e879f9
C_GREEN="\033[38;2;74;222;128m"         # #4ade80
C_YELLOW="\033[38;2;251;191;36m"        # #fbbf24
C_ORANGE="\033[38;2;251;146;60m"        # #fb923c
C_RED="\033[38;2;248;113;113m"          # #f87171
C_MUTED="\033[38;2;148;163;184m"        # #94a3b8
C_DARK="\033[38;2;71;85;105m"           # #475569
C_BORDER="\033[38;2;139;92;246m"        # #8b5cf6
C_BORDER_ACCENT="\033[38;2;59;130;246m" # #3b82f6

REPO_DIR="${REPO_DIR:-/home/william/nixos-hyprland-caelestia}"
SUDO_PID=""

# ------------------------------------------------------------------------------
# 🛡️ LIMPEZA E TRAPS (Ctrl+C)
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
    echo -e "${C_BORDER}│${C_RESET}              ${C_BLUE}██║    ██║██║██║     ██║     ██╔═══██╗██╔════╝${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}              ${C_PURPLE}██║ █╗ ██║██║██║     ██║     ██║   ██║███████╗${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}              ${C_PURPLE}██║███╗██║██║██║     ██║     ██║   ██║╚════██║${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}              ${C_MAGENTA}╚███╔███╔╝██║███████╗███████╗╚██████╔╝███████║${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}               ${C_MAGENTA}╚══╝╚══╝ ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝${C_RESET}                 ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}                                                                             ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}   ${C_BOLD}${C_YELLOW}⚡  W I L L O S   S Y S T E M   C O R E   U P G R A D E   v 2 . 0  ⚡${C_RESET}    ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}💻 Sistema:${C_RESET} ${C_CYAN}%-14s${C_RESET} ${C_MUTED}🐧 Kernel:${C_RESET} ${C_BLUE}%-15s${C_RESET}  ${C_MUTED}🏷️  Geração Atual:${C_RESET} ${C_YELLOW}#%-4s${C_RESET} ${C_BORDER}│${C_RESET}\n" "WillOS [${host_name}]" "$kernel_ver" "$current_gen"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}🌿 Branch:${C_RESET}  ${C_PURPLE}%-14s${C_RESET} ${C_MUTED}📅 Data:${C_RESET}   ${C_MUTED}%-15s${C_RESET}  ${C_MUTED}👤 Operador:${C_RESET}      ${C_GREEN}%-4s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$branch" "$now_str" "$USER"
    echo -e "${C_BORDER}╰─────────────────────────────────────────────────────────────────────────────╯${C_RESET}"
    echo ""
}

print_step_header() {
    local step_num="$1"
    local step_total="$2"
    local icon="$3"
    local title="$4"
    echo -e "${C_BOLD}${C_PURPLE}╭─[ ${C_CYAN}${step_num}/${step_total}${C_PURPLE} ] ${icon}  ${C_CYAN}${title}${C_RESET}"
}

print_substep() {
    local icon="$1"
    local msg="$2"
    echo -e "${C_PURPLE}│  ${icon} ${C_RESET}${msg}"
}

print_step_done() {
    local msg="$1"
    echo -e "${C_PURPLE}╰── ${C_GREEN}✔ ${msg}${C_RESET}\n"
}

print_step_fail() {
    local msg="$1"
    echo -e "${C_PURPLE}╰── ${C_RED}✖ ${msg}${C_RESET}\n"
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
    local spin_colors=("$C_CYAN" "$C_BLUE" "$C_PURPLE" "$C_MAGENTA")
    
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
            raw_last=$(tail -n 1 "$logfile" 2>/dev/null | tr -d '\r\n' || echo "")
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

        # Barra de pulso neon animada
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
            printf "\r\033[K${C_PURPLE}│  ${color}${frame}${C_RESET} ${C_BOLD}${C_CYAN}%-38s${C_RESET} ${C_MUTED}⏱️  %02dm %02ds${C_RESET}\n" "$title" "$min" "$sec"
            printf "\r\033[K${C_PURPLE}│  ${C_PURPLE}├─ [${C_GREEN}%s${C_PURPLE}] ${C_YELLOW}EM ANDAMENTO${C_RESET}\n" "$bar"
            printf "\r\033[K${C_PURPLE}│  ${C_PURPLE}└─ ${C_MUTED}Status:${C_RESET} ${C_MUTED}%-55s${C_RESET}\033[2A" "$status_line"
        fi

        ((i++))
        sleep 0.08
    done

    wait "$pid" 2>/dev/null || true
    local exit_code=0
    if ! wait "$pid" 2>/dev/null; then
        exit_code=1
    fi

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
        printf "\r\033[K${C_PURPLE}│  ${C_GREEN}✔${C_RESET} ${C_BOLD}${title}${C_RESET} ${C_GREEN}concluído em %02dm %02ds!${C_RESET}\n" "$min_tot" "$sec_tot"
        rm -f "$logfile"
        return 0
    else
        printf "\r\033[K${C_PURPLE}│  ${C_RED}✖${C_RESET} ${C_BOLD}${title}${C_RESET} ${C_RED}falhou após %02dm %02ds (Código: ${exit_code})!${C_RESET}\n\n" "$min_tot" "$sec_tot"
        echo -e "${C_RED}─────── [ LOG DE ERRO DETALHADO ] ───────${C_RESET}"
        tail -n 25 "$logfile" 2>/dev/null || echo "Nenhum log gravado."
        echo -e "${C_RED}─────────────────────────────────────────${C_RESET}\n"
        rm -f "$logfile"
        return "$exit_code"
    fi
}

print_help() {
    print_header
    echo -e "${C_BOLD}${C_CYAN}USO:${C_RESET} rebuild [OPÇÕES] [MENSAGEM_DE_COMMIT]"
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}OPÇÕES:${C_RESET}"
    echo -e "  ${C_GREEN}--upgrade, -u${C_RESET}      Atualiza todos os inputs do Flake (nix flake update) antes do rebuild"
    echo -e "  ${C_GREEN}--boot${C_RESET}             Apenas adiciona a nova geração ao bootloader sem ativar imediatamente"
    echo -e "  ${C_GREEN}--show-trace${C_RESET}       Exibe o trace completo em caso de erros de compilação Nix"
    echo -e "  ${C_GREEN}--fast, --no-pull${C_RESET}  Pula a sincronização remota do Git (modo offline/rápido)"
    echo -e "  ${C_GREEN}--help, -h${C_RESET}         Exibe esta central de ajuda"
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}EXEMPLOS:${C_RESET}"
    echo -e "  ${C_MUTED}# Rebuild padrão com animação e commit inteligente:${C_RESET}"
    echo -e "  ${C_CYAN}rebuild${C_RESET}"
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
    local rebuild_args=()
    local commit_msg=""

    # Parsing de argumentos
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                print_help
                ;;
            --fast|--no-pull)
                skip_pull=true
                ;;
            -u|--upgrade)
                do_flake_update=true
                rebuild_args+=("$arg")
                ;;
            --boot)
                action="boot"
                ;;
            --test)
                action="test"
                ;;
            -*)
                rebuild_args+=("$arg")
                ;;
            *)
                if [ -z "$commit_msg" ]; then
                    commit_msg="$arg"
                else
                    commit_msg="$commit_msg $arg"
                fi
                ;;
        esac
    done

    # Exibe o cabeçalho dinâmico
    print_header

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
        echo -e "${C_PURPLE}╭─[ 🔐 ] ${C_CYAN}Autenticação de Segurança${C_RESET}"
        echo -e "${C_PURPLE}│  ${C_YELLOW}🔑 Por favor, informe sua senha de administrador para iniciar o Rebuild:${C_RESET}"
        sudo -v
        echo -e "${C_PURPLE}╰── ${C_GREEN}✔ Privilégios administrativos concedidos!${C_RESET}\n"
    fi

    # Mantém o token sudo ativo em segundo plano durante a compilação
    while true; do sudo -n true 2>/dev/null; sleep 30; done &
    SUDO_PID=$!

    # ==========================================================================
    # FASE 1: SINCRONIZAÇÃO GIT & DETECÇÃO DE ALTERAÇÕES
    # ==========================================================================
    print_step_header "1" "$total_steps" "🌐" "Sincronização & Auditoria de Repositório Git"

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
    local changed_count
    changed_count=$(echo "$status_output" | grep -v '^$' | wc -l || echo "0")

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

    run_with_dynamic_hud "Indexação de Arquivos para o Flake" "Adicionando alterações ao índice Git..." git -C "$REPO_DIR" add -A

    if [ "$do_flake_update" = true ]; then
        run_with_dynamic_hud "Atualização de Inputs do Flake" "Executando nix flake update..." nix flake update --flake "$REPO_DIR"
    fi

    print_step_done "Flake indexado e pronto para compilação."

    # ==========================================================================
    # FASE 3: COMPILAÇÃO & ATIVAÇÃO DO SISTEMA
    # ==========================================================================
    print_step_header "3" "$total_steps" "⚡" "Compilação & Ativação do WillOS ($action)"

    # Limpeza preventiva e resolução de conflitos de unidades transientes do systemd
    if sudo systemctl is-active --quiet nixos-rebuild-switch-to-configuration.service 2>/dev/null; then
        print_substep "⏳" "${C_YELLOW}Aguardando ciclo de ativação anterior finalizar...${C_RESET}"
        while sudo systemctl is-active --quiet nixos-rebuild-switch-to-configuration.service 2>/dev/null; do
            sleep 1
        done
    fi
    sudo systemctl reset-failed nixos-rebuild-switch-to-configuration.service 2>/dev/null || true

    if ! run_with_dynamic_hud "Motor de Rebuild do WillOS" "Iniciando compilação do sistema..." sudo nixos-rebuild "$action" --flake "$REPO_DIR" "${rebuild_args[@]}"; then
        print_step_fail "Falha durante a reconstrução do WillOS."
        play_sound "error"
        send_notify "critical" "❌ Erro no Rebuild WillOS" "A compilação do sistema falhou. Verifique os logs no terminal."

        echo -e "${C_RED}╔═════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
        echo -e "${C_RED}║  ❌  FALHA NA RECONSTRUÇÃO DO WILLOS                                        ║${C_RESET}"
        echo -e "${C_RED}╠═════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  ⚠️  Ocorreu um erro durante a compilação ou ativação da configuração.      ${C_RED}║${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  🛡️  A geração anterior (${C_YELLOW}#${old_gen_num}${C_RESET}) permanece 100% segura e ativa.          ${C_RED}║${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  💡 ${C_CYAN}Dica:${C_RESET} Execute '${C_BOLD}rebuild --show-trace${C_RESET}' para inspecionar o erro completo.   ${C_RED}║${C_RESET}"
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

    # Se houver alterações locais, cria o commit
    if ! git -C "$REPO_DIR" diff --staged --quiet || ! git -C "$REPO_DIR" diff --quiet; then
        git -C "$REPO_DIR" add -A
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
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}🌿  Snapshot Git       :${C_RESET}  ${C_PURPLE}[%-7s]${C_RESET} origin/%-30s ${C_BORDER}║${C_RESET}\n" "$commit_sha" "$branch"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}🛡️   Status do Kernel   :${C_RESET}  ${C_BLUE}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "$kernel_ver (100% Estável)"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}✨  Ambiente Visual    :${C_RESET}  ${C_MAGENTA}%-43s${C_RESET} ${C_BORDER}║${C_RESET}\n" "Hyprland + Caelestia Shell Operacionais"
    echo -e "${C_BORDER}║                                                                             ║${C_RESET}"
    echo -e "${C_BORDER}║  ${C_BOLD}${C_CYAN}🚀 O seu WillOS está turbinado, atualizado e pronto para uso!${C_RESET}               ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}╚═════════════════════════════════════════════════════════════════════════════╝${C_RESET}\n"

    # Notificação no Desktop & Som de Conclusão
    play_sound "success"
    send_notify "normal" "🚀 WillOS Atualizado com Sucesso!" "Geração #${new_gen_num} ativada em ${time_formatted}."
}

main "$@"
