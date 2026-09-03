#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 6 ]; then
    echo "Uso: willos-auto-sync REPOSITORIO USUARIO HOME BRANCH ACAO NIXOS_REBUILD" >&2
    exit 2
fi

REPO_DIR="$1"
REPO_USER="$2"
REPO_HOME="$3"
BRANCH="$4"
ACTION="$5"
NIXOS_REBUILD="$6"
STATE_DIR="${WILLOS_AUTO_SYNC_STATE_DIR:-/var/lib/willos-auto-sync}"
APPLIED_REVISION_FILE="$STATE_DIR/applied-revision"
LOCK_FILE="${WILLOS_AUTO_SYNC_LOCK_FILE:-/run/lock/willos-auto-sync.lock}"

log() {
    echo "willos-auto-sync: $*"
}

user_git() {
    if [ "$(id -un)" = "$REPO_USER" ]; then
        env HOME="$REPO_HOME" git -C "$REPO_DIR" "$@"
    else
        runuser -u "$REPO_USER" -- env HOME="$REPO_HOME" git -C "$REPO_DIR" "$@"
    fi
}

assert_private_local_files() {
    local local_path
    for local_path in hardware-configuration.nix local-config.nix; do
        if [ ! -f "$REPO_DIR/$local_path" ]; then
            log "arquivo local obrigatorio ausente: $local_path"
            return 1
        fi
        if user_git ls-files --error-unmatch -- "$local_path" >/dev/null 2>&1; then
            log "arquivo local esta rastreado pelo Git: $local_path"
            return 1
        fi
        if ! user_git check-ignore -q -- "$local_path"; then
            log "arquivo local deixou de ser ignorado pelo Git: $local_path"
            return 1
        fi
    done
}

mkdir -p "$STATE_DIR"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    log "outra sincronizacao ja esta em andamento; encerrando esta rodada"
    exit 0
fi

if [ ! -d "$REPO_DIR/.git" ] || [ ! -f "$REPO_DIR/flake.nix" ]; then
    log "repositorio invalido: $REPO_DIR"
    exit 1
fi

assert_private_local_files

# Nunca mistura uma atualizacao remota com trabalho local ainda nao concluido.
if [ -n "$(user_git status --porcelain --untracked-files=normal)" ]; then
    log "arvore de trabalho possui alteracoes locais; sincronizacao adiada"
    exit 0
fi

local_revision=$(user_git rev-parse HEAD)
origin_url=$(user_git remote get-url origin)
fetch_url="$origin_url"

# O repositorio publico pode ser consultado por HTTPS sem depender do ssh-agent
# da sessao grafica. A URL configurada para push permanece inalterada.
case "$origin_url" in
    git@github.com:*)
        fetch_url="https://github.com/${origin_url#git@github.com:}"
        ;;
    ssh://git@github.com/*)
        fetch_url="https://github.com/${origin_url#ssh://git@github.com/}"
        ;;
esac

log "consultando $BRANCH em $fetch_url"
user_git fetch --quiet --no-tags "$fetch_url" "$BRANCH"
remote_revision=$(user_git rev-parse FETCH_HEAD)

# Confere novamente depois da operacao de rede para evitar sobrescrever uma
# edicao que tenha comecado enquanto o fetch estava em andamento.
if [ -n "$(user_git status --porcelain --untracked-files=normal)" ] || \
   [ "$(user_git rev-parse HEAD)" != "$local_revision" ]; then
    log "o repositorio mudou durante a consulta; sincronizacao adiada"
    exit 0
fi

updated=false
if [ "$local_revision" = "$remote_revision" ]; then
    log "nenhum commit remoto novo"
elif user_git merge-base --is-ancestor "$local_revision" "$remote_revision"; then
    log "novo commit remoto detectado; aplicando fast-forward"
    user_git merge --ff-only --quiet "$remote_revision"
    updated=true
elif user_git merge-base --is-ancestor "$remote_revision" "$local_revision"; then
    log "checkout local esta a frente do remoto; nenhuma alteracao aplicada"
    exit 0
else
    log "historicos local e remoto divergiram; intervencao manual necessaria"
    exit 1
fi

current_revision=$(user_git rev-parse HEAD)
assert_private_local_files

# Na primeira execucao, o checkout atual foi necessariamente aplicado pelo
# rebuild que instalou este timer. Apenas registra esse ponto de partida.
if [ ! -f "$APPLIED_REVISION_FILE" ] && [ "$updated" = false ]; then
    printf '%s\n' "$current_revision" > "$APPLIED_REVISION_FILE"
    log "estado inicial registrado"
    exit 0
fi

if [ -f "$APPLIED_REVISION_FILE" ] && \
   [ "$(cat "$APPLIED_REVISION_FILE")" = "$current_revision" ]; then
    exit 0
fi

log "executando nixos-rebuild $ACTION para ${current_revision:0:12}"
FLAKE_DIR="$REPO_DIR" "$NIXOS_REBUILD" "$ACTION" \
    --impure --flake "$REPO_DIR#willos"

printf '%s\n' "$current_revision" > "$APPLIED_REVISION_FILE"
log "revisao ${current_revision:0:12} aplicada com sucesso"
