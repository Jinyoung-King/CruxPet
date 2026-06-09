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
    local SIGN_UPDATE_PATH
    SIGN_UPDATE_PATH=$(find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 6 -name "sign_update" 2>/dev/null | head -1)
    if [[ -z "$SIGN_UPDATE_PATH" ]]; then
        echo "❌ Sparkle sign_update를 찾을 수 없습니다. Xcode에서 한 번 빌드해주세요." >&2
        exit 1
    fi
    SPARKLE_BIN=$(dirname "$SIGN_UPDATE_PATH")

    echo "✅ Preflight 통과"
    echo "   버전: $VERSION"
    echo "   Sparkle: $SPARKLE_BIN"
}

# ── 버전 번프 ──────────────────────────────────────────────────────────
bump_version() {
    echo "📝 버전 번프 중: $VERSION"

    local PBXPROJ="$REPO_ROOT/CruxPet.xcodeproj/project.pbxproj"

    # 현재 build number 읽기
    local CURRENT_BUILD
    CURRENT_BUILD=$(grep -m1 "CURRENT_PROJECT_VERSION" "$PBXPROJ" | tr -dc '0-9')
    local NEW_BUILD=$(( CURRENT_BUILD + 1 ))

    # MARKETING_VERSION 교체 (전체)
    sed -i '' "s/MARKETING_VERSION = [0-9][0-9.]*;/MARKETING_VERSION = ${VERSION};/g" "$PBXPROJ"

    # CURRENT_PROJECT_VERSION 교체 (전체)
    sed -i '' "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD};/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "$PBXPROJ"

    # 교체 확인
    if ! grep -q "MARKETING_VERSION = ${VERSION};" "$PBXPROJ"; then
        echo "❌ MARKETING_VERSION 번프 실패 — pbxproj 형식을 확인하세요." >&2
        exit 1
    fi
    if ! grep -q "CURRENT_PROJECT_VERSION = ${NEW_BUILD};" "$PBXPROJ"; then
        echo "❌ CURRENT_PROJECT_VERSION 번프 실패 — pbxproj 형식을 확인하세요." >&2
        exit 1
    fi

    echo "   빌드 번호: ${CURRENT_BUILD} → ${NEW_BUILD}"

    git -C "$REPO_ROOT" add "$PBXPROJ"
    git -C "$REPO_ROOT" commit -m "chore: bump version to ${VERSION} (build ${NEW_BUILD})"
    echo "✅ 버전 번프 완료"
}

# ── 빌드 ───────────────────────────────────────────────────────────────
build_app() {
    echo "🔨 빌드 중..."

    xcodebuild archive \
        -scheme CruxPet \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=macOS" \
        -quiet

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$SCRIPT_DIR/ExportOptions.plist" \
        -quiet

    echo "✅ 빌드 완료"
}

# ── DMG 생성 ────────────────────────────────────────────────────────────
create_dmg() {
    echo "📦 DMG 생성 중..."

    local DMG_PATH="$REPO_ROOT/$DMG_NAME"

    # hdiutil이 .dmg를 자동으로 붙이므로 확장자 제거 후 전달
    hdiutil create \
        -volname "CruxPet" \
        -srcfolder "$EXPORT_PATH/CruxPet.app" \
        -ov \
        -format UDZO \
        "${DMG_PATH%.dmg}"

    echo "✅ DMG 생성: $DMG_NAME ($(du -h "$DMG_PATH" | cut -f1))"
}

preflight
echo "🚀 릴리즈 $VERSION 시작"
bump_version
build_app
create_dmg
