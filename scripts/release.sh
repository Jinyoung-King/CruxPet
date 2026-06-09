#!/usr/bin/env bash
set -euo pipefail

# ── 인자 ──────────────────────────────────────────────────────────────
VERSION="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ARCHIVE_PATH="/tmp/CruxPet.xcarchive"
EXPORT_PATH="/tmp/CruxPet-export"
DMG_NAME="CruxPet-${VERSION}.dmg"
RELEASE_CREATED=false

# ── 정리 ──────────────────────────────────────────────────────────────
cleanup() {
    rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
    if [ "$RELEASE_CREATED" = true ]; then
        echo ""
        echo "⚠️  GitHub release v${VERSION}이 생성됐습니다. 수동으로 삭제하려면:"
        echo "    gh release delete v${VERSION} --cleanup-tag"
    fi
}
trap cleanup EXIT

# ── Preflight ─────────────────────────────────────────────────────────
preflight() {
    echo "🔍 Preflight 검사 중..."

    # 버전 인자 확인
    if [[ -z "$VERSION" ]]; then
        echo "❌ 버전을 지정하세요: ./scripts/release.sh 1.0.6" >&2
        exit 1
    fi

    # X.Y.Z 형식 확인
    if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "❌ 버전 형식 오류 (X.Y.Z 필요): $VERSION" >&2
        exit 1
    fi

    # gh CLI 로그인 확인
    if ! gh auth status &>/dev/null; then
        echo "❌ gh CLI 로그인 필요: gh auth login" >&2
        exit 1
    fi

    # git working tree 클린 확인
    if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
        echo "❌ git working tree에 uncommitted 변경사항이 있습니다." >&2
        git -C "$REPO_ROOT" status --short >&2
        exit 1
    fi

    # xcodebuild 확인
    if ! xcodebuild -version &>/dev/null; then
        echo "❌ Xcode 커맨드라인 툴 필요: xcode-select --install" >&2
        exit 1
    fi

    # Sparkle sign_update 경로 탐색
    SPARKLE_BIN=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 6 -name "sign_update" 2>/dev/null | head -1 | xargs -I{} dirname {})
    if [[ -z "$SPARKLE_BIN" ]]; then
        echo "❌ Sparkle sign_update를 찾을 수 없습니다. Xcode에서 한 번 빌드해주세요." >&2
        exit 1
    fi

    echo "✅ Preflight 통과"
    echo "   버전: $VERSION"
    echo "   Sparkle: $SPARKLE_BIN"
}

preflight
echo "🚀 릴리즈 $VERSION 시작"
