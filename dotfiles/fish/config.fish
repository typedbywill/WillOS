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

# Função para reconstruir o sistema e sincronizar com o Git automaticamente
function rebuild
    set -l repo "/home/william/nixos-hyprland-caelestia"
    set -l branch (git -C $repo branch --show-current)
    set -l rebuild_args
    set -l commit_msg ""

    for arg in $argv
        if string match -q -- "-*" $arg
            set -a rebuild_args $arg
        else
            set commit_msg $arg
        end
    end

    if test -z "$commit_msg"
        set commit_msg "rebuild: "(date "+%Y-%m-%d %H:%M:%S")
    end

    echo "📦 Preparando arquivos para o Nix Flake..."
    git -C $repo add -A

    echo "❄️  Reconstruindo o NixOS..."
    if sudo nixos-rebuild switch --flake "$repo#nixos" $rebuild_args
        # Se houver alterações locais não commitadas, cria o commit
        if not git -C $repo diff --staged --quiet
            git -C $repo commit -m "$commit_msg"
        end

        echo "🚀 Enviando alterações para origin/$branch..."
        if git -C $repo push origin $branch
            echo "✅ Sistema reconstruído e repositório sincronizado com sucesso!"
        else
            echo "⚠️  O rebuild funcionou, mas houve uma falha ao enviar para o Git (push)."
        end
    else
        echo "❌ Falha no rebuild do NixOS. Nenhum commit/push foi enviado."
        return 1
    end
end

