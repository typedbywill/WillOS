#!/usr/bin/env bash
set -uo pipefail

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
        --apply) ;;
    esac
    shift
done

if [ "$REPORT_ONLY" = false ] && [ "$NON_INTERACTIVE" = false ] \
    && [ "${WILLOS_APP_UPDATES_APPROVED:-false}" != true ] \
    && { [ ! -t 0 ] || [ ! -t 1 ]; }; then
    NON_INTERACTIVE=true
fi

APP_ID="wacli"
APP_NAME="wacli"
RECIPE="$REPO_DIR/pkgs/wacli.nix"
APP_VERSION="$(sed -n 's/^[[:space:]]*version = "\([^"]*\)";.*/\1/p' "$RECIPE" | head -n1)"

if [ -z "$APP_VERSION" ] || ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "ℹ️  Verificação de apps ignorada: versão, curl ou jq indisponível."
    exit 0
fi

release_json="$(curl --fail --silent --show-error --location --max-time 8 \
    -H 'Accept: application/vnd.github+json' \
    'https://api.github.com/repos/openclaw/wacli/releases/latest' 2>/dev/null || true)"
if [ -z "$release_json" ]; then
    echo "ℹ️  Não foi possível consultar a versão upstream de $APP_NAME; mantendo a configuração atual."
    exit 0
fi

latest_tag="$(jq -r '.tag_name // empty' <<< "$release_json" 2>/dev/null || true)"
latest_version="${latest_tag#v}"
if [[ ! "$latest_tag" =~ ^v[0-9]+([.][0-9]+)*$ || ! "$APP_VERSION" =~ ^[0-9]+([.][0-9]+)*$ ]]; then
    echo "ℹ️  Formato de versão não suportado para $APP_NAME ($APP_VERSION → ${latest_tag:-?}); sem alterações."
    exit 0
fi

asset_json="$(jq -c --arg name "wacli_${latest_version}_linux_amd64.tar.gz" '[.assets[]? | select(.name == $name)]' <<< "$release_json" 2>/dev/null || true)"
if [ "$(jq 'length' <<< "${asset_json:-[]}" 2>/dev/null || echo 0)" -ne 1 ]; then
    echo "ℹ️  Asset Linux amd64 ausente ou ambíguo no release de $APP_NAME; sem alterações."
    exit 0
fi
asset_name="$(jq -r '.[0].name' <<< "$asset_json")"
asset_url="$(jq -r '.[0].browser_download_url // empty' <<< "$asset_json")"
asset_digest="$(jq -r '.[0].digest // empty' <<< "$asset_json")"
asset_size="$(jq -r '.[0].size // 0' <<< "$asset_json")"
if [ "$asset_name" != "wacli_${latest_version}_linux_amd64.tar.gz" ] \
    || [ "$asset_url" != "https://github.com/openclaw/wacli/releases/download/${latest_tag}/${asset_name}" ] \
    || [[ ! "$asset_digest" =~ ^sha256:[0-9a-f]{64}$ ]] \
    || [[ ! "$asset_size" =~ ^[1-9][0-9]*$ ]]; then
    echo "ℹ️  Metadados de integridade inválidos para $APP_NAME; sem alterações."
    exit 0
fi
expected_sha256="${asset_digest#sha256:}"

version_gt() {
    local left="$1" right="$2"
    local IFS=.
    local -a lparts rparts
    read -r -a lparts <<< "$left"
    read -r -a rparts <<< "$right"
    local i l r count=${#lparts[@]}
    [ "${#rparts[@]}" -gt "$count" ] && count=${#rparts[@]}
    for ((i=0; i<count; i++)); do
        l=${lparts[i]:-0}; r=${rparts[i]:-0}
        l=$((10#$l)); r=$((10#$r))
        (( l > r )) && return 0
        (( l < r )) && return 1
    done
    return 1
}

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

if ! version_gt "$latest_version" "$APP_VERSION"; then
    [ "$REPORT_ONLY" = true ] && echo "✓ $APP_NAME está atualizado ($APP_VERSION)."
    exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "ℹ️  Nova versão de $APP_NAME: $APP_VERSION → $latest_version; python3 indisponível para preferências locais."
    exit 0
fi
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
    echo "   Asset verificado pelo digest SHA-256 publicado pela API do GitHub; modo somente relatório."
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
        if [ "${WILLOS_APP_UPDATES_APPROVED:-false}" != true ]; then
            echo "   A receita não foi alterada: confirme primeiro o rebuild do sistema."
            exit 0
        fi
        if ! command -v tar >/dev/null 2>&1 || ! command -v sha256sum >/dev/null 2>&1; then
            echo "   Não há ferramentas para validar o asset; receita não alterada."
            exit 0
        fi
        tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/willos-wacli-update.XXXXXX")" || exit 0
        trap 'rm -rf "$tmp_dir"' EXIT
        archive="$tmp_dir/$asset_name"
        if ! curl --fail --silent --show-error --location --max-time 90 "$asset_url" -o "$archive"; then
            echo "   Falha ao baixar o asset; receita não alterada."
            exit 0
        fi
        actual_size="$(wc -c < "$archive" | tr -d '[:space:]')"
        actual_sha256="$(sha256sum "$archive" | awk '{print $1}')"
        if [ "$actual_size" != "$asset_size" ] || [ "$actual_sha256" != "$expected_sha256" ]; then
            echo "   O asset não corresponde ao tamanho/digest do GitHub; receita não alterada."
            exit 0
        fi
        if ! tar -tzf "$archive" | grep -Eq '(^|/)wacli$'; then
            echo "   Arquivo sem o binário esperado; receita não alterada."
            exit 0
        fi
        old_sha256="$(sed -n 's/^[[:space:]]*sha256 = "\([^"]*\)";.*/\1/p' "$RECIPE" | head -n1)"
        if [ -z "$old_sha256" ] || ! grep -Fq "version = \"$APP_VERSION\";" "$RECIPE"; then
            echo "   A receita mudou inesperadamente; atualização cancelada sem sobrescrever alterações."
            exit 0
        fi
        tmp_recipe="$(mktemp "$(dirname "$RECIPE")/.wacli.nix.XXXXXX")" || exit 0
        if ! python3 -I - "$RECIPE" "$tmp_recipe" "$APP_VERSION" "$latest_version" "$old_sha256" "$expected_sha256" <<'PY'
import pathlib, re, sys
source, target, old_version, new_version, old_hash, new_hash = sys.argv[1:]
text = pathlib.Path(source).read_text()
version_pattern = re.compile(r'(?m)^(\s*version = )"' + re.escape(old_version) + r'";\s*$')
hash_pattern = re.compile(r'(?m)^(\s*sha256 = )"' + re.escape(old_hash) + r'";\s*$')
if len(version_pattern.findall(text)) != 1 or len(hash_pattern.findall(text)) != 1:
    raise SystemExit("Recipe fields are ambiguous")
text = version_pattern.sub(lambda m: m.group(1) + '"' + new_version + '";', text, count=1)
text = hash_pattern.sub(lambda m: m.group(1) + '"' + new_hash + '";', text, count=1)
pathlib.Path(target).write_text(text)
PY
        then
            rm -f "$tmp_recipe"
            echo "   Não foi possível atualizar os pins; receita preservada."
            exit 0
        fi
        chmod --reference="$RECIPE" "$tmp_recipe" 2>/dev/null || chmod 0644 "$tmp_recipe"
        mv -f "$tmp_recipe" "$RECIPE"
        echo "   Receita atualizada: wacli $APP_VERSION → $latest_version; o rebuild prosseguirá para instalar a nova versão."
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
