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

# Alias para reconstruir o sistema direto do seu repositório
alias rebuild="git -C /home/william/nixos-hyprland-caelestia add -A && sudo nixos-rebuild switch --flake /home/william/nixos-hyprland-caelestia#nixos"
