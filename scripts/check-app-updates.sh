#!/usr/bin/env bash
set -uo pipefail

# Optional, app-specific upstream checker. Only entries with an explicit,
# reproducible update strategy are listed here; this is not a nixpkgs updater.
REPO_DIR="${WILLOS_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$STATE_HOME/willos"
STATE_FILE="$STATE_DIR/app-update-checker.json"
REPORT_ONLY=false
NON_INTERACTIVE=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --report-only) REPORT_ONLY=true ;;
        --non-interactive) NON_INTERACTIVE=true ;;
    esac
    shift
done

if [ "$REPORT_ONLY" = false ] && [ "$NON_INTERACTIVE" = false ] && { [ ! -t 0 ] || [ ! -t 1 ]; }; then
    NON_INTERACTIVE=true
fi

# Initial allowlist is intentionally narrow: wacli has a stable GitHub release
# endpoint; other custom apps need independent source and integrity validation.
APP_ID="wacli"
APP_NAME="wacli"
APP_VERSION="$(sed -n 's/^[[:space:]]*version = "\([^"]*\)";.*/\1/p' "$REPO_DIR/pkgs/wacli.nix" | head -n1)"

if [ -z "$APP_VERSION" ] || ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "ℹ️  Verificação de apps ignorada: versão, curl ou jq indisponível."
    exit 0
fi

latest_tag=""
latest_tag=$(curl --fail --silent --show-error --location --max-time 8 \
    -H 'Accept: application/vnd.github+json' \
    'https://api.github.com/repos/openclaw/wacli/releases/latest' 2>/dev/null \
    | jq -r '.tag_name // empty' 2>/dev/null || true)
latest_version="${latest_tag#v}"

if [ -z "$latest_version" ]; then
    echo "ℹ️  Não foi possível consultar a versão upstream de $APP_NAME; mantendo a configuração atual."
    exit 0
fi

# Compare numeric dotted versions; if the upstream format changes, fail closed.
if [[ ! "$APP_VERSION" =~ ^[0-9]+([.][0-9]+)*$ || ! "$latest_version" =~ ^[0-9]+([.][0-9]+)*$ ]]; then
    echo "ℹ️  Formato de versão não suportado para $APP_NAME ($APP_VERSION → $latest_version); sem alterações."
    exit 0
fi

version_gt() {
    local left="$1" right="$2"
    local IFS=.
    local -a lparts rparts
    read -r -a lparts <<< "$left"
    read -r -a rparts <<< "$right"
    local i l r
    local count=${#lparts[@]}
    [ "${#rparts[@]}" -gt "$count" ] && count=${#rparts[@]}
    for ((i=0; i<count; i++)); do
        l=${lparts[i]:-0}; r=${rparts[i]:-0}
        # Avoid octal interpretation of leading zeroes.
        l=$((10#$l)); r=$((10#$r))
        if (( l > r )); then return 0; fi
        if (( l < r )); then return 1; fi
    done
    return 1
}

if ! version_gt "$latest_version" "$APP_VERSION"; then
    [ "$REPORT_ONLY" = true ] && echo "✓ $APP_NAME está atualizado ($APP_VERSION)."
    exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "ℹ️  Nova versão de $APP_NAME: $latest_version (atual: $APP_VERSION); python3 indisponível para preferências locais."
    exit 0
fi

mkdir -p "$STATE_DIR" 2>/dev/null || true

state_get() {
    python3 -I - "$STATE_FILE" "$APP_ID" "$latest_version" <<'PY'
import json, sys
path, app, version = sys.argv[1:]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    ignored = data.get("ignored_apps", [])
    versions = data.get("ignored_versions", {})
    print("ignored" if app in ignored else "version" if version in versions.get(app, []) else "ask")
except (OSError, ValueError, TypeError, AttributeError):
    print("ask")
PY
}

state_add() {
    local mode="$1"
    python3 -I - "$STATE_FILE" "$APP_ID" "$latest_version" "$mode" <<'PY'
import json, os, sys, tempfile
path, app, version, mode = sys.argv[1:]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        data = {}
except (OSError, ValueError, TypeError):
    data = {}
ignored = data.setdefault("ignored_apps", [])
versions = data.setdefault("ignored_versions", {})
if not isinstance(ignored, list):
    ignored = data["ignored_apps"] = []
if not isinstance(versions, dict):
    versions = data["ignored_versions"] = {}
if mode == "ignored":
    if app not in ignored:
        ignored.append(app)
else:
    entries = versions.setdefault(app, [])
    if not isinstance(entries, list):
        entries = versions[app] = []
    if version not in entries:
        entries.append(version)
os.makedirs(os.path.dirname(path), mode=0o700, exist_ok=True)
fd, tmp = tempfile.mkstemp(prefix=".app-update-", dir=os.path.dirname(path))
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)
        f.write("\n")
    os.chmod(tmp, 0o600)
    os.replace(tmp, path)
finally:
    if os.path.exists(tmp):
        os.unlink(tmp)
PY
}

preference="$(state_get)"
if [ "$preference" = ignored ]; then
    [ "$REPORT_ONLY" = true ] && echo "↷ $APP_NAME: ignorado permanentemente nas preferências locais."
    exit 0
elif [ "$preference" = version ]; then
    [ "$REPORT_ONLY" = true ] && echo "↷ $APP_NAME $latest_version: versão dispensada nas preferências locais."
    exit 0
fi

echo "⬆️  Atualização disponível: $APP_NAME $APP_VERSION → $latest_version"
if [ "$REPORT_ONLY" = true ]; then
    echo "   Atualizador dedicado: wacli (GitHub Releases); nenhuma alteração feita no modo --info."
    exit 0
fi
if [ "$NON_INTERACTIVE" = true ]; then
    echo "   Sem prompt em modo não interativo; atualização deixada pendente."
    exit 0
fi

printf 'Escolha: [1] Atualizar  [2] Pular por enquanto  [3] Não perguntar para essa versão  [4] Ignorar sempre esse App: '
choice=""
read -r choice || choice=2
case "$choice" in
    1)
        echo "   Atualizador individual de wacli ainda não está habilitado: a API de releases não fornece o hash Nix validado."
        echo "   Nenhuma receita foi alterada. A versão permanece pendente para nova consulta."
        ;;
    2|"")
        echo "   Pulado por enquanto; será consultado novamente no próximo rebuild."
        ;;
    3)
        if state_add version; then echo "   $APP_NAME $latest_version dispensado; versões futuras ainda serão consultadas."; fi
        ;;
    4)
        if state_add ignored; then echo "   $APP_NAME ignorado permanentemente neste usuário."; fi
        ;;
    *)
        echo "   Opção inválida; atualização deixada pendente."
        ;;
esac
