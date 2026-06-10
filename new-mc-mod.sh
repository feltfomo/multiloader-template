#!/usr/bin/env bash
# new-mc-mod.sh — cargo-new for this multiloader template, no Nix required.
#
# Copies the tracked template/ into a fresh directory (build output excluded) and
# runs the bundled scaffolder (template/scaffold.sh) to rewrite the placeholder
# identity (modid / Modid / com.example.modid / yourname) and rename packages.
#
#   ./new-mc-mod.sh                                  # interactive
#   ./new-mc-mod.sh nexus fomo.dev.nexus "Nexus"
#
# Opt into extra JVM languages (default Java-only):
#   SCAFFOLD_KOTLIN=1 SCAFFOLD_SCALA=1 ./new-mc-mod.sh nexus fomo.dev.nexus "Nexus"
#
# No clone? Use Nix instead (copies only tracked files, always clean):
#   nix run github:feltfomo/multiloader-template#new -- nexus fomo.dev.nexus "Nexus"
#   nix flake new -t github:feltfomo/multiloader-template ./nexus && cd nexus && ./scaffold.sh
#   npx degit feltfomo/multiloader-template/template nexus && cd nexus && ./scaffold.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/template"
[ -d "$src" ] || { echo "error: $src not found — run this from the cloned repo root." >&2; exit 1; }

id="${1:-}"
group="${2:-}"
name="${3:-}"

if [ -z "$id" ]; then read -r -p "mod id (lowercase): " id; fi
if [ -z "$group" ]; then
  read -r -p "group / package [com.example.$id]: " group
  group="${group:-com.example.$id}"
fi

dest="$id"
[ -e "$dest" ] && { echo "error: ./$dest already exists" >&2; exit 1; }

# warn if the new project would land inside the template repo (notion-sync, git, etc.)
if [ "$PWD" = "$here" ]; then
  echo "note: you are inside the template repo, so ./$id lands here and gets picked up"
  echo "      by git / notion-sync. cd somewhere else (e.g. ~/Projects) to keep mods separate."
fi

echo "copying template -> ./$id (excluding build output)"
mkdir -p "$dest"
tar -C "$src" \
  --exclude='./.git' \
  --exclude='./build' --exclude='*/build' \
  --exclude='*/.gradle' --exclude='*/.kotlin' \
  --exclude='*/run' \
  -cf - . | tar -C "$dest" -xf -
chmod -R u+w "$dest"

(
  cd "$dest"
  SCAFFOLD_ID="$id" SCAFFOLD_GROUP="$group" SCAFFOLD_NAME="$name" \
    SCAFFOLD_KOTLIN="${SCAFFOLD_KOTLIN:-}" SCAFFOLD_SCALA="${SCAFFOLD_SCALA:-}" \
    ./scaffold.sh
)

echo
echo "created ./$id"
echo "  cd $id"
echo "  nix develop          # dev shell lives in the generated project, not the repo root"
echo "  ./gradlew :fabric:runClient"
