# Desativa mensagem padrão de boas-vindas do fish
set -g fish_greeting ""

if status is-interactive
    # Aplica a paleta de cores dinâmica do Caelestia no terminal
    if test -f "$HOME/.local/state/caelestia/sequences.txt"
        cat "$HOME/.local/state/caelestia/sequences.txt"
    end

    # Exibe informações do sistema com Fastfetch
    if type -q fastfetch
        fastfetch
    end
end

# Aliases práticos
alias ll="ls -lah --color=auto"
alias la="ls -A --color=auto"
alias l="ls -CF --color=auto"
alias grep="grep --color=auto"
alias scheme="caelestia scheme"
alias restart-caelestia="restart-caelestia"
alias caelestia-restart="restart-caelestia"

function restart-caelestia --description "Reiniciar a barra e interface do Caelestia"
    echo "🔄 Reiniciando Caelestia Shell..."
    caelestia shell -k 2>/dev/null
    set -l count 0
    while pgrep -f quickshell >/dev/null
        sleep 0.1
        set count (math $count + 1)
        if test $count -ge 15
            pkill -9 -f quickshell 2>/dev/null
            break
        end
    end
    sleep 0.2
    caelestia shell -d
    echo "✨ Caelestia reiniciado com sucesso!"
end

function reboot-windows
    if type -q efibootmgr
        sudo efibootmgr -n 0000 && sudo reboot
    else
        sudo nix-shell -p efibootmgr --run "efibootmgr -n 0000" && sudo reboot
    end
end

# Função para reconstruir o sistema e sincronizar com o Git automaticamente (Modo Grande Atualização)
function rebuild --description "Reconstruir o WillOS com visual dinâmico e estatísticas completas"
    set -l script_repo "$HOME/nixos-hyprland-caelestia/scripts/rebuild.sh"
    set -l script_config "$HOME/.config/scripts/rebuild.sh"

    if test -f "$script_repo"
        bash "$script_repo" $argv
    else if test -f "$script_config"
        bash "$script_config" $argv
    else
        echo "❌ Script de rebuild não encontrado em $script_repo"
        return 1
    end
end

# Autocompletes interativos do comando rebuild
complete -c rebuild -l host -s H -d "Especificar target do Flake (padrão: willos)"
complete -c rebuild -l yes -s y -d "Pular confirmação interativa pré-rebuild"
complete -c rebuild -l info -d "Inspecionar compatibilidade de hardware e discos sem rebuild"
complete -c rebuild -l dry-run -d "Apenas auditar configurações sem aplicar nada"
complete -c rebuild -l upgrade -s u -d "Atualizar todos os inputs do Flake (nix flake update)"
complete -c rebuild -l boot -d "Adicionar ao bootloader sem ativar imediatamente"
complete -c rebuild -l test -d "Testar configuração temporariamente sem alterar boot padrão"
complete -c rebuild -l show-trace -d "Exibir trace detalhado de erros de compilação"
complete -c rebuild -l fast -d "Pular sincronização do Git (modo rápido)"
complete -c rebuild -l no-pull -d "Pular git pull"
complete -c rebuild -l help -s h -d "Exibir central de ajuda da atualização"


