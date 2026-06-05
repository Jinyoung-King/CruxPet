#!/bin/sh
set -e

HOOKS_DIR="$HOME/.config/git/hooks"
HOOK_FILE="$HOOKS_DIR/post-commit"
EVENTS_DIR="$HOME/.cruxpet"
EVENTS_FILE="$EVENTS_DIR/events.json"
HOOK_LINE='echo "{\"type\":\"commit\",\"timestamp\":$(date +%s)}" >> "$HOME/.cruxpet/events.json"'

# 디렉터리 생성
mkdir -p "$HOOKS_DIR"
mkdir -p "$EVENTS_DIR"
touch "$EVENTS_FILE"

# post-commit hook 파일 생성 또는 append
if [ ! -f "$HOOK_FILE" ]; then
    printf '#!/bin/sh\n%s\n' "$HOOK_LINE" > "$HOOK_FILE"
else
    if ! grep -qF "cruxpet" "$HOOK_FILE"; then
        printf '\n# CruxPet\n%s\n' "$HOOK_LINE" >> "$HOOK_FILE"
    fi
fi
chmod +x "$HOOK_FILE"

# git global hooksPath 설정
git config --global core.hooksPath "$HOOKS_DIR"

echo "✅ CruxPet git hook 설치 완료"
echo "   hook:  $HOOK_FILE"
echo "   events: $EVENTS_FILE"
