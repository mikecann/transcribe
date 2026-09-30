#!/usr/bin/env bash
# Link the launcher from this clone. Re-run after moving the clone.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/bin"
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: bash install.sh [target_bin_dir]"
      echo "Then run: bash deps.sh [--with-diarize]"
      exit 0
      ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done

mkdir -p "$TARGET_DIR"
# A directory here would make ln create a link inside it instead of the command.
if [[ -e "$TARGET_DIR/transcribe" && ! -L "$TARGET_DIR/transcribe" ]]; then
  echo "Refusing to replace an existing file or directory: $TARGET_DIR/transcribe" >&2
  exit 1
fi
chmod +x "$REPO_DIR/transcribe"
ln -sfn "$REPO_DIR/transcribe" "$TARGET_DIR/transcribe"
echo "Installed $TARGET_DIR/transcribe -> $REPO_DIR/transcribe"
case ":$PATH:" in
  *":$TARGET_DIR:"*) ;;
  *) echo "Add to ~/.zshrc or ~/.bashrc: export PATH=\"$TARGET_DIR:\$PATH\"" ;;
esac
echo "Install dependencies once: bash \"$REPO_DIR/deps.sh\""
