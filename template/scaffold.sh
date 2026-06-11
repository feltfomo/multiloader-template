#!/usr/bin/env bash
# scaffold.sh — turn this copied template into your own mod, cargo-new style.
#
# Rewrites the placeholder identity baked into the template:
#   modid              -> your mod id
#   Modid              -> your display name
#   com.example.modid  -> your group / package (dirs get renamed too)
#   yourname           -> author
# ...then deletes itself. Run it in-place right after copying the template
# (via `nix flake new -t ...`, degit, or the bundled new-mc-mod.sh):
#
#   ./scaffold.sh                                   # interactive
#   SCAFFOLD_ID=foo SCAFFOLD_GROUP=com.acme.foo \
#     ./scaffold.sh --non-interactive               # automation
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# placeholder identity baked into the template
OLD_ID="modid"

NONINTERACTIVE="false"
for arg in "$@"; do
  case "$arg" in
    --non-interactive|-y) NONINTERACTIVE="true" ;;
  esac
done

# prompt VAR "label" "default"  (uses default when non-interactive or no tty)
prompt() {
  local __var="$1" __label="$2" __default="$3" __reply=""
  if [ "$NONINTERACTIVE" = "true" ] || [ ! -t 0 ]; then
    printf -v "$__var" "%s" "$__default"
    return
  fi
  read -r -p "$__label [$__default]: " __reply || true
  printf -v "$__var" "%s" "${__reply:-$__default}"
}

# normalize an env value (1/true/yes/y -> true, anything else -> false)
truthy() { case "$1" in 1|true|TRUE|yes|YES|y|Y) printf '%s' true ;; *) printf '%s' false ;; esac; }

# yesno VAR "label" "default(true|false)"  (uses default when non-interactive)
yesno() {
  local __var="$1" __label="$2" __default="$3" __reply="" __hint="y/N"
  [ "$__default" = "true" ] && __hint="Y/n"
  if [ "$NONINTERACTIVE" = "true" ] || [ ! -t 0 ]; then
    printf -v "$__var" "%s" "$__default"
    return
  fi
  read -r -p "$__label [$__hint]: " __reply || true
  case "$__reply" in
    [yY]|[yY][eE][sS]) printf -v "$__var" "true" ;;
    [nN]|[nN][oO])     printf -v "$__var" "false" ;;
    "")                printf -v "$__var" "%s" "$__default" ;;
    *)                 printf -v "$__var" "false" ;;
  esac
}

# seed from env so the flake app / new-mc-mod.sh can drive this headlessly
MOD_ID="${SCAFFOLD_ID:-}"
MOD_GROUP="${SCAFFOLD_GROUP:-}"
MOD_NAME="${SCAFFOLD_NAME:-}"
MOD_VERSION="${SCAFFOLD_VERSION:-1.0.0}"
MOD_AUTHORS="${SCAFFOLD_AUTHORS:-yourname}"
MOD_LICENSE="${SCAFFOLD_LICENSE:-MIT}"
MOD_DESC="${SCAFFOLD_DESC:-A Minecraft mod.}"
MOD_KOTLIN="${SCAFFOLD_KOTLIN:-}"
MOD_SCALA="${SCAFFOLD_SCALA:-}"
MOD_DATAGEN="${SCAFFOLD_DATAGEN:-}"

[ -z "$MOD_ID" ]    && prompt MOD_ID    "mod id (lowercase)" "mymod"
[ -z "$MOD_GROUP" ] && prompt MOD_GROUP "group / package"    "com.example.$MOD_ID"

# default display name from the id: my_cool_mod -> MyCoolMod
default_name="$(printf '%s' "$MOD_ID" | sed -E 's/(^|_)([a-z])/\U\2/g')"
[ -z "$MOD_NAME" ] && prompt MOD_NAME "display name" "$default_name"

if [ "$NONINTERACTIVE" != "true" ] && [ -t 0 ]; then
  prompt MOD_VERSION "version"     "$MOD_VERSION"
  prompt MOD_AUTHORS "authors"     "$MOD_AUTHORS"
  prompt MOD_LICENSE "license"     "$MOD_LICENSE"
  prompt MOD_DESC    "description" "$MOD_DESC"
fi
[ -z "$MOD_NAME" ] && MOD_NAME="$default_name"

# languages: java is always on; kotlin/scala are opt-in (env or prompt, default off)
if [ -n "$MOD_KOTLIN" ]; then MOD_KOTLIN="$(truthy "$MOD_KOTLIN")"; else yesno MOD_KOTLIN "add kotlin support" "false"; fi
if [ -n "$MOD_SCALA" ];  then MOD_SCALA="$(truthy "$MOD_SCALA")";   else yesno MOD_SCALA  "add scala support"  "false"; fi

# datagen rides on by default -- it's part of the normal workflow, not an extra
# language. Off prunes the sample providers below; on Fabric they wouldn't even
# compile, since fabric-api is gated on this same flag.
if [ -n "$MOD_DATAGEN" ]; then MOD_DATAGEN="$(truthy "$MOD_DATAGEN")"; else yesno MOD_DATAGEN "include datagen" "true"; fi

# validate the structural identifiers (these end up in package + manifest)
if ! printf '%s' "$MOD_ID" | grep -Eq '^[a-z][a-z0-9_]*$'; then
  echo "error: mod id must match ^[a-z][a-z0-9_]*$ (got: $MOD_ID)" >&2; exit 1
fi
if ! printf '%s' "$MOD_GROUP" | grep -Eq '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$'; then
  echo "error: group must look like com.example.$MOD_ID (got: $MOD_GROUP)" >&2; exit 1
fi

MOD_GROUP_PATH="${MOD_GROUP//.//}"

echo "scaffolding:"
echo "  id      $MOD_ID"
echo "  name    $MOD_NAME"
echo "  group   $MOD_GROUP"
echo "  version $MOD_VERSION"
echo "  authors $MOD_AUTHORS"
echo "  license $MOD_LICENSE"
echo "  kotlin  $MOD_KOTLIN"
echo "  scala   $MOD_SCALA"
echo "  datagen $MOD_DATAGEN"

# escape a string for the replacement side of  sed s|...|REPL|
sed_repl() { printf '%s' "$1" | sed -e 's/[&|\]/\\&/g'; }
R_NAME="$(sed_repl "$MOD_NAME")"
R_AUTHORS="$(sed_repl "$MOD_AUTHORS")"
R_LICENSE="$(sed_repl "$MOD_LICENSE")"
R_DESC="$(sed_repl "$MOD_DESC")"
R_VERSION="$(sed_repl "$MOD_VERSION")"

is_text() { grep -Iq . "$1"; }

# the set of text files we are allowed to touch (skip vcs, build output, binaries, self)
text_files() {
  find . -type f \
    -not -path './.git/*' \
    -not -path '*/build/*' \
    -not -path '*/.gradle/*' \
    -not -path '*/.kotlin/*' \
    -not -name 'gradle-wrapper.jar' \
    -not -name 'scaffold.sh' \
    -print0
}

# 1) structural identifiers everywhere. group first so the bare `modid` token
#    replace can't corrupt the already-rewritten package string. capitalized
#    `Modid` is the display-name placeholder (e.g. the README title); the pkl
#    name line gets reset in step 2 too, so this just covers prose elsewhere.
text_files | while IFS= read -r -d '' f; do
  is_text "$f" || continue
  sed -i \
    -e "s|com\.example\.modid|$MOD_GROUP|g" \
    -e "s|com/example/modid|$MOD_GROUP_PATH|g" \
    -e "s|\bmodid\b|$MOD_ID|g" \
    -e "s|\bModid\b|$R_NAME|g" \
    -e "s|yourname|$R_AUTHORS|g" \
    "$f"
done

# 2) identity + flags, which live only in pkl/mod.pkl now. gradle.properties used
#    to carry mod_name/version/etc, but that moved to pkl (the root build reads
#    identity from there), so there's nothing left to rewrite in it.
if [ -f pkl/mod.pkl ]; then
  sed -i \
    -e "s|^name = .*|name = \"$R_NAME\"|" \
    -e "s|^version = .*|version = \"$R_VERSION\"|" \
    -e "s|^license = .*|license = \"$R_LICENSE\"|" \
    -e "s|^description = .*|description = \"$R_DESC\"|" \
    -e "s|^kotlin: Boolean = .*|kotlin: Boolean = $MOD_KOTLIN|" \
    -e "s|^scala: Boolean = .*|scala: Boolean = $MOD_SCALA|" \
    -e "s|^datagen: Boolean = .*|datagen: Boolean = $MOD_DATAGEN|" \
    pkl/mod.pkl
fi

# 3) rename the package directories  com/example/modid -> <group path>
find . -type d -path '*/com/example/modid' -print0 | while IFS= read -r -d '' pkgdir; do
  newdir="${pkgdir/com\/example\/modid/$MOD_GROUP_PATH}"
  [ "$pkgdir" = "$newdir" ] && continue
  mkdir -p "$newdir"
  shopt -s dotglob nullglob
  mv "$pkgdir"/* "$newdir"/ 2>/dev/null || true
  shopt -u dotglob nullglob
done

# prune the emptied old package chain (only when empty, so shared prefixes survive)
find . -depth -type d -path '*/com/example/modid' -empty -delete 2>/dev/null || true
find . -depth -type d -path '*/com/example'       -empty -delete 2>/dev/null || true
find . -depth -type d -path '*/com'               -empty -delete 2>/dev/null || true

# 4) any leftover file/dir still carrying the bare id in its name (deepest first)
find . -depth -name "*${OLD_ID}*" \
  -not -path './.git/*' -not -path '*/build/*' \
  -not -path '*/.gradle/*' -not -path '*/.kotlin/*' 2>/dev/null | while IFS= read -r p; do
  [ -e "$p" ] || continue
  d="$(dirname "$p")"; b="$(basename "$p")"
  nb="${b//$OLD_ID/$MOD_ID}"
  [ "$b" = "$nb" ] && continue
  mv "$p" "$d/$nb"
done

# drop the sample sources for languages you didn't pick. scope to the mod
# modules only -- buildSrc/src/main/kotlin is the build itself, never touch it.
prune_lang() {
  for m in common fabric neoforge; do
    find "$m/src" -type d -name "$1" -prune -print0 2>/dev/null | xargs -0 -r rm -rf
  done
}
[ "$MOD_KOTLIN" = "true" ] || prune_lang kotlin
[ "$MOD_SCALA" = "true" ]  || prune_lang scala

# datagen off: drop each loader's sample provider package and any generated
# output. Not just tidiness -- the Fabric sources import fabric-api, which the
# build only pulls in when datagen is on, so leaving them would break compile.
prune_datagen() {
  for m in fabric neoforge; do
    find "$m/src" -type d -name datagen -prune -print0 2>/dev/null | xargs -0 -r rm -rf
  done
  rm -rf fabric/src/main/generated neoforge/src/generated 2>/dev/null || true
}
[ "$MOD_DATAGEN" = "true" ] || prune_datagen

# gradlew and the mcw bootstrap lose their +x bit when the template round-trips
# through Notion sync (pages don't store unix permissions), so restore them.
chmod +x gradlew mcw 2>/dev/null || true

echo "done. removing scaffold.sh"
rm -f -- "$ROOT/scaffold.sh"

cat <<'NEXT'

next:
  ./mcw :fabric:runClient          # grabs JDK 25 if you lack it, then runs gradle
  ./mcw :neoforge:runClient
  # set up already (nix develop, or your own JDK 25)? use ./gradlew instead
NEXT
