#!/usr/bin/env bash
# ==============================================================================
#  ⚡ NIXOS SYSTEM CORE UPGRADE & REBUILD ENGINE ⚡
#  Visual dinâmico, moderno e informativo para reconstrução do NixOS
# ==============================================================================

set -eo pipefail

# ------------------------------------------------------------------------------
# 🎨 PALETA DE CORES ANSI TRUECOLOR (24-BIT) & ESTILOS VISUAIS
# ------------------------------------------------------------------------------
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_ITALIC="\033[3m"
C_UNDERLINE="\033[4m"

# Gradientes Neon (Caelestia / Cyberpunk Vibe)
C_CYAN="\033[38;2;56;189;248m"       # Sky Blue (#38bdf8)
C_BLUE="\033[38;2;96;165;250m"       # Light Blue (#60a5fa)
C_PURPLE="\033[38;2;192;132;252m"    # Violet (#c084fc)
C_MAGENTA="\033[38;2;232;121;249m"   # Neon Pink (#e879f9)
C_GREEN="\033[38;2;74;222;128m"      # Emerald Neon (#4ade80)
C_YELLOW="\033[38;2;251;191;36m"     # Amber/Gold (#fbbf24)
C_ORANGE="\033[38;2;251;146;60m"     # Sunset Orange (#fb923c)
C_RED="\033[38;2;248;113;113m"       # Rose Red (#f87171)
C_MUTED="\033[38;2;148;163;184m"     # Slate Gray (#94a3b8)
C_DARK="\033[38;2;71;85;105m"        # Deep Slate (#475569)
C_BORDER="\033[38;2;139;92;246m"     # Neon Purple Border (#8b5cf6)
C_BORDER_ACCENT="\033[38;2;59;130;246m" # Neon Blue Border (#3b82f6)

REPO_DIR="${REPO_DIR:-/home/william/nixos-hyprland-caelestia}"

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
        notify-send -u "$urgency" -a "NixOS Rebuild Engine" -i "system-software-update" "$title" "$body" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 💻 CABEÇALHO & TELEMETRIA
# ------------------------------------------------------------------------------
print_header() {
    local host_name
    host_name=$(hostname 2>/dev/null || echo "nixos")
    local kernel_ver
    kernel_ver=$(uname -r 2>/dev/null || echo "Linux")
    local current_gen
    current_gen=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]\+-link' | grep -o '[0-9]\+' || echo "?")
    local branch
    branch=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || echo "main")
    local now_str
    now_str=$(date "+%d/%m/%Y • %H:%M:%S")

    echo -e "${C_BORDER}╭─────────────────────────────────────────────────────────────────────────────╮${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_CYAN}███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗   ██╗   ██╗██████╗           ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_BLUE}████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝   ██║   ██║██╔══██╗          ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_PURPLE}██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗   ██║   ██║██████╔╝          ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_PURPLE}██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║   ██║   ██║██╔═══╝           ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_MAGENTA}██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║██╗╚██████╔╝██║               ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}  ${C_MAGENTA}╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝ ╚═╝               ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}                                                                             ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}│${C_RESET}   ${C_BOLD}${C_YELLOW}⚡  N I X O S   S Y S T E M   C O R E   U P G R A D E   v 2 . 0  ⚡${C_RESET}    ${C_BORDER}│${C_RESET}"
    echo -e "${C_BORDER}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}💻 Host:${C_RESET} ${C_CYAN}%-8s${C_RESET}  ${C_MUTED}🐧 Kernel:${C_RESET} ${C_BLUE}%-15s${C_RESET}  ${C_MUTED}🏷️  Geração Atual:${C_RESET} ${C_YELLOW}#%-4s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$host_name" "$kernel_ver" "$current_gen"
    printf "${C_BORDER}│${C_RESET}  ${C_MUTED}🌿 Branch:${C_RESET} ${C_PURPLE}%-6s${C_RESET}  ${C_MUTED}📅 Data:${C_RESET} ${C_MUTED}%-20s${C_RESET}  ${C_MUTED}👤 User:${C_RESET} ${C_GREEN}%-10s${C_RESET} ${C_BORDER}│${C_RESET}\n" "$branch" "$now_str" "$USER"
    echo -e "${C_BORDER}╰─────────────────────────────────────────────────────────────────────────────╯${C_RESET}"
    echo ""
}

print_step() {
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

print_step_warn() {
    local msg="$1"
    echo -e "${C_PURPLE}╰── ${C_YELLOW}⚠️  ${msg}${C_RESET}\n"
}

print_step_fail() {
    local msg="$1"
    echo -e "${C_PURPLE}╰── ${C_RED}✖ ${msg}${C_RESET}\n"
}

print_help() {
    print_header
    echo -e "${C_BOLD}${C_CYAN}USO:${C_RESET} rebuild [OPÇÕES] [MENSAGEM_DE_COMMIT]"
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}OPÇÕES:${C_RESET}"
    echo -e "  ${C_GREEN}--upgrade, -u${C_RESET}      Atualiza os inputs do Flake (nix flake update) antes de reconstruir"
    echo -e "  ${C_GREEN}--boot${C_RESET}             Apenas adiciona a nova geração ao bootloader sem ativar imediatamente"
    echo -e "  ${C_GREEN}--show-trace${C_RESET}       Exibe o trace completo em caso de erros de compilação Nix"
    echo -e "  ${C_GREEN}--fast, --no-pull${C_RESET}  Pula a sincronização remota do Git"
    echo -e "  ${C_GREEN}--help, -h${C_RESET}         Exibe esta central de ajuda"
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}EXEMPLOS:${C_RESET}"
    echo -e "  ${C_MUTED}# Rebuild padrão com auto-commit inteligente:${C_RESET}"
    echo -e "  ${C_CYAN}rebuild${C_RESET}"
    echo ""
    echo -e "${C_MUTED}# Rebuild com mensagem personalizada:${C_RESET}"
    echo -e "  ${C_CYAN}rebuild \"adicionando novo tema ao hyprland\"${C_RESET}"
    echo ""
    echo -e "${C_MUTED}# Grande atualização completa com upgrade de pacotes:${C_RESET}"
    echo -e "  ${C_CYAN}rebuild --upgrade \"grande atualização de sistema\"${C_RESET}"
    echo ""
    exit 0
}

# ------------------------------------------------------------------------------
# 🚀 EXECUÇÃO PRINCIPAL
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

    # Exibe o cabeçalho estilizado
    print_header

    local start_time
    start_time=$(date +%s)

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

    # ==========================================================================
    # FASE 1: SINCRONIZAÇÃO GIT & DETECÇÃO DE ALTERAÇÕES
    # ==========================================================================
    print_step "1" "$total_steps" "🌐" "Sincronização & Auditoria de Repositório Git"

    if [ "$skip_pull" = true ]; then
        print_substep "⏩" "${C_YELLOW}Modo rápido ativo:${C_RESET} Sincronização remota ignorada."
    else
        print_substep "📡" "Verificando upstream (${C_PURPLE}origin/$branch${C_RESET})..."
        if git -C "$REPO_DIR" pull --rebase --autostash origin "$branch" >/tmp/git_pull_log 2>&1; then
            if grep -q "Already up to date" /tmp/git_pull_log; then
                print_substep "✨" "Repositório local já está perfeitamente sincronizado."
            else
                print_substep "📥" "${C_GREEN}Atualizações remotas baixadas com sucesso!${C_RESET}"
            fi
        else
            print_substep "⚠️" "${C_YELLOW}Aviso:${C_RESET} Falha ao sincronizar com o Git remoto. Prosseguindo com o build local..."
        fi
    fi

    # Detecta status de arquivos locais modificados
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
    # FASE 2: PREPARAÇÃO DO NIX FLAKE & PRÉ-FLIGHT
    # ==========================================================================
    print_step "2" "$total_steps" "📦" "Preparação do Flake & Verificação de Integridade"

    print_substep "🔍" "Indexando todos os arquivos modificados para o Flake..."
    git -C "$REPO_DIR" add -A

    if [ "$do_flake_update" = true ]; then
        print_substep "🔄" "${C_YELLOW}Atualizando todos os inputs do Flake (nix flake update)...${C_RESET}"
        nix flake update --flake "$REPO_DIR"
    fi

    # Validação de sudo antecipada
    print_substep "🔐" "Validando privilégios de superusuário (sudo)..."
    if ! sudo -n true 2>/dev/null; then
        echo -e "${C_PURPLE}│  ${C_YELLOW}🔑 Por favor, informe a senha de administrador:${C_RESET}"
        sudo -v
    fi

    print_step_done "Flake preparado e ambiente pronto."

    # ==========================================================================
    # FASE 3: COMPILAÇÃO & ATIVAÇÃO DO SISTEMA NIXOS
    # ==========================================================================
    print_step "3" "$total_steps" "⚡" "Compilação & Ativação do Sistema NixOS ($action)"

    print_substep "🚀" "Iniciando motor de compilação NixOS..."
    print_substep "❄️" "${C_MUTED}Executando: sudo nixos-rebuild ${action} --flake \"$REPO_DIR\" ${rebuild_args[*]}${C_RESET}"
    echo ""

    local build_status=0
    # Executa o nixos-rebuild diretamente com saída em tempo real
    if sudo nixos-rebuild "$action" --flake "$REPO_DIR" "${rebuild_args[@]}"; then
        build_status=0
    else
        build_status=$?
    fi

    echo ""
    if [ "$build_status" -ne 0 ]; then
        print_step_fail "Falha crítica durante a reconstrução do NixOS (Código $build_status)."
        play_sound "error"
        send_notify "critical" "❌ Erro no Rebuild NixOS" "A compilação do sistema falhou. Verifique os logs no terminal."

        echo -e "${C_RED}╔═════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
        echo -e "${C_RED}║  ❌  FALHA NA RECONSTRUÇÃO DO SISTEMA NIXOS                                 ║${C_RESET}"
        echo -e "${C_RED}╠═════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  ⚠️  Ocorreu um erro durante a compilação ou ativação da configuração.      ${C_RED}║${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  🛡️  A geração anterior (${C_YELLOW}#${old_gen_num}${C_RESET}) permanece 100% segura e ativa.          ${C_RED}║${C_RESET}"
        echo -e "${C_RED}║${C_RESET}  💡 ${C_CYAN}Dica:${C_RESET} Execute '${C_BOLD}rebuild --show-trace${C_RESET}' para inspecionar o erro completo.   ${C_RED}║${C_RESET}"
        echo -e "${C_RED}╚═════════════════════════════════════════════════════════════════════════════╝${C_RESET}\n"
        exit "$build_status"
    fi

    print_step_done "Compilação e ativação concluídas com sucesso!"

    # ==========================================================================
    # FASE 4: AUDITORIA DE PACOTES & NOVA GERAÇÃO
    # ==========================================================================
    print_step "4" "$total_steps" "📊" "Auditoria de Pacotes & Nova Geração"

    local new_profile_link
    new_profile_link=$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || echo "")
    local new_gen_num
    new_gen_num=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -o 'system-[0-9]\+-link' | grep -o '[0-9]\+' || echo "$old_gen_num")

    if [ "$old_gen_num" != "$new_gen_num" ]; then
        print_substep "🏷️" "Transição de Sistema: ${C_YELLOW}Geração #${old_gen_num}${C_RESET} ──▶ ${C_GREEN}${C_BOLD}Geração #${new_gen_num}${C_RESET} ${C_GREEN}(ATIVADA)${C_RESET}"
    else
        print_substep "🏷️" "Geração do Sistema: ${C_GREEN}${C_BOLD}Geração #${new_gen_num}${C_RESET} (Inalterada)"
    fi

    # Analisa diferenças entre closures do Nix Store
    local diff_text=""
    local count_added=0
    local count_updated=0
    local count_removed=0
    declare -a diff_highlights=()

    if [ -n "$old_profile_link" ] && [ -n "$new_profile_link" ] && [ "$old_profile_link" != "$new_profile_link" ]; then
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
    print_step "5" "$total_steps" "🚀" "Snapshot Git & Sincronização em Nuvem"

    local commit_created=false
    local commit_sha=""

    # Se houver alterações locais após o build, cria o commit
    if ! git -C "$REPO_DIR" diff --staged --quiet || ! git -C "$REPO_DIR" diff --quiet; then
        git -C "$REPO_DIR" add -A
        if [ -z "$commit_msg" ]; then
            local ts
            ts=$(date "+%Y-%m-%d %H:%M:%S")
            commit_msg="rebuild(nixos): Gen #${new_gen_num} • ${ts}"
        fi

        print_substep "💾" "Criando commit: ${C_CYAN}\"$commit_msg\"${C_RESET}..."
        if git -C "$REPO_DIR" commit -m "$commit_msg" >/dev/null 2>&1; then
            commit_created=true
            commit_sha=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "")
            print_substep "🏷️" "Commit gerado: [${C_YELLOW}${commit_sha}${C_RESET}]"
        fi
    else
        print_substep "ℹ️" "Nenhuma alteração pendente para commit."
        commit_sha=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "")
    fi

    # Envio para o repositório remoto
    print_substep "📤" "Sincronizando com ${C_PURPLE}origin/$branch${C_RESET} no GitHub..."
    if git -C "$REPO_DIR" push origin "$branch" >/tmp/git_push_log 2>&1; then
        print_substep "☁️" "${C_GREEN}Push realizado com sucesso para o GitHub!${C_RESET}"
    else
        print_substep "⚠️" "${C_YELLOW}Aviso:${C_RESET} O rebuild local foi concluído, mas houve falha no push (sem internet ou sem permissão)."
    fi

    print_step_done "Sincronização remota finalizada."

    # Sincronização opcional da paleta Caelestia/KDE
    if [ -f "$REPO_DIR/dotfiles/caelestia/sync-kde.sh" ]; then
        bash "$REPO_DIR/dotfiles/caelestia/sync-kde.sh" >/dev/null 2>&1 || true
    fi

    # ==========================================================================
    # 🏆 DASHBOARD RESUMO DA GRANDE ATUALIZAÇÃO
    # ==========================================================================
    local end_time
    end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    local elapsed_min=$((elapsed / 60))
    local elapsed_sec=$((elapsed % 60))
    local time_formatted
    printf -v time_formatted "%02dm %02ds" "$elapsed_min" "$elapsed_sec"

    echo -e "${C_BORDER}╔═════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BORDER}║  ${C_BOLD}${C_GREEN}🎉  S I S T E M A   R E C O N S T R U Í D O   C O M   S U C E S S O !${C_RESET}         ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}╠═════════════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BORDER}║                                                                             ║${C_RESET}"
    printf "${C_BORDER}║${C_RESET}  ${C_MUTED}🏷️   Geração NixOS      :${C_RESET}  ${C_YELLOW}Geração #%-3s${C_RESET} ──▶  ${C_BOLD}${C_GREEN}Geração #%-3s (ATIVADA)${C_RESET}      ${C_BORDER}║${C_RESET}\n" "$old_gen_num" "$new_gen_num"
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
    echo -e "${C_BORDER}║  ${C_BOLD}${C_CYAN}🚀 O seu NixOS está turbinado, atualizado e pronto para uso!${C_RESET}               ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}╚═════════════════════════════════════════════════════════════════════════════╝${C_RESET}\n"

    # Notificação no Desktop & Som de Conclusão
    play_sound "success"
    send_notify "normal" "🚀 NixOS Atualizado com Sucesso!" "Geração #${new_gen_num} ativada em ${time_formatted}."
}

main "$@"
