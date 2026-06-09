# Release Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `./scripts/release.sh 1.0.6` 한 번으로 버전 번프 → 빌드 → GitHub 릴리즈 → appcast 업데이트 → push까지 전체 배포 파이프라인 자동화.

**Architecture:** 단일 bash 스크립트(`set -euo pipefail`)가 모든 단계를 순차 실행. Sparkle의 `sign_update` 툴로 DMG 서명, `python3`으로 appcast.xml 생성, `gh` CLI로 GitHub Release 생성/업로드. 실패 시 `trap`으로 임시 파일 정리 + 안내 메시지 출력.

**Tech Stack:** bash, xcodebuild, hdiutil, Sparkle sign_update, python3, gh CLI

---

## File Map

| 파일 | 상태 | 역할 |
|---|---|---|
| `scripts/release.sh` | 신규 | 전체 릴리즈 파이프라인 |
| `scripts/ExportOptions.plist` | 신규 | xcodebuild exportArchive 설정 |
| `.gitignore` | 수정 | `*.dmg` 추가 |

---

### Task 1: 스캐폴딩 — scripts 디렉터리, ExportOptions.plist, .gitignore

**Files:**
- Create: `scripts/ExportOptions.plist`
- Modify: `.gitignore`

- [ ] **Step 1: scripts 디렉터리 생성 + ExportOptions.plist 작성**

```bash
mkdir -p scripts
```

`scripts/ExportOptions.plist` 내용:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
```

- [ ] **Step 2: .gitignore에 *.dmg 추가**

`.gitignore` 끝에 추가:
```
# DMG builds (uploaded to GitHub Releases, not committed)
*.dmg
```

- [ ] **Step 3: 검증**

```bash
cat scripts/ExportOptions.plist
grep "\.dmg" .gitignore
```

Expected:
```
# DMG builds (uploaded to GitHub Releases, not committed)
*.dmg
```

- [ ] **Step 4: 커밋**

```bash
git add scripts/ExportOptions.plist .gitignore
git commit -m "chore: release scripts 스캐폴딩 및 .gitignore 업데이트"
```

---

### Task 2: release.sh — 스켈레톤 + Preflight 검사

**Files:**
- Create: `scripts/release.sh`

Preflight: 버전 형식(X.Y.Z), gh 로그인, git 클린, xcodebuild, Sparkle sign_update 경로.

- [ ] **Step 1: release.sh 스켈레톤 작성**

`scripts/release.sh`:
```bash
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
```

- [ ] **Step 2: 실행 권한 부여**

```bash
chmod +x scripts/release.sh
```

- [ ] **Step 3: Preflight 검사 — 버전 누락 테스트**

```bash
./scripts/release.sh 2>&1 || true
```

Expected:
```
❌ 버전을 지정하세요: ./scripts/release.sh 1.0.6
```

- [ ] **Step 4: Preflight 검사 — 잘못된 형식 테스트**

```bash
./scripts/release.sh 1.0 2>&1 || true
```

Expected:
```
❌ 버전 형식 오류 (X.Y.Z 필요): 1.0
```

- [ ] **Step 5: Preflight 검사 — 정상 버전 통과 테스트**

```bash
./scripts/release.sh 99.99.99 2>&1 || true
```

Expected (preflight 통과 후 스크립트가 "🚀 릴리즈 99.99.99 시작" 출력):
```
🔍 Preflight 검사 중...
✅ Preflight 통과
   버전: 99.99.99
   Sparkle: /Users/.../bin
🚀 릴리즈 99.99.99 시작
```

- [ ] **Step 6: 커밋**

```bash
git add scripts/release.sh
git commit -m "feat: release.sh 스켈레톤 및 preflight 검사 추가"
```

---

### Task 3: release.sh — 버전 번프 + 빌드 + DMG

**Files:**
- Modify: `scripts/release.sh`

`preflight` 호출 이후에 세 함수 추가: `bump_version`, `build_app`, `create_dmg`.

- [ ] **Step 1: bump_version 함수 추가**

`release.sh`의 `preflight` 함수 아래에 추가:
```bash
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

    echo "   빌드 번호: ${CURRENT_BUILD} → ${NEW_BUILD}"

    git -C "$REPO_ROOT" add "$PBXPROJ"
    git -C "$REPO_ROOT" commit -m "chore: bump version to ${VERSION} (build ${NEW_BUILD})"
    echo "✅ 버전 번프 완료"
}
```

- [ ] **Step 2: build_app 함수 추가**

```bash
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
```

- [ ] **Step 3: create_dmg 함수 추가**

```bash
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
```

- [ ] **Step 4: 스크립트 하단에 함수 호출 추가**

`preflight` 와 `echo "🚀 릴리즈 $VERSION 시작"` 이후 라인에 추가:
```bash
bump_version
build_app
create_dmg
```

- [ ] **Step 5: 버전 번프 로직 단위 검증**

실제 스크립트를 실행하지 않고, sed 명령어만 따로 테스트:
```bash
# 현재 버전 확인
grep "MARKETING_VERSION" CruxPet.xcodeproj/project.pbxproj | head -2
```

Expected: `MARKETING_VERSION = 1.0.5;` 가 4줄

```bash
# sed dry-run (실제 파일 변경 없이 출력 확인)
sed "s/MARKETING_VERSION = [0-9][0-9.]*;/MARKETING_VERSION = 9.9.9;/g" \
    CruxPet.xcodeproj/project.pbxproj | grep "MARKETING_VERSION"
```

Expected: `MARKETING_VERSION = 9.9.9;` 가 4줄

- [ ] **Step 6: 커밋**

```bash
git add scripts/release.sh
git commit -m "feat: release.sh 버전 번프, 빌드, DMG 생성 추가"
```

---

### Task 4: release.sh — GitHub 릴리즈 + appcast 업데이트 + 마무리

**Files:**
- Modify: `scripts/release.sh`

세 함수 추가: `create_github_release`, `update_appcast`, `finalize`.

- [ ] **Step 1: create_github_release 함수 추가**

```bash
# ── GitHub 릴리즈 ────────────────────────────────────────────────────────
create_github_release() {
    echo "🚀 GitHub 릴리즈 생성 중..."

    local DMG_PATH="$REPO_ROOT/$DMG_NAME"

    gh release create "v${VERSION}" \
        --title "v${VERSION}" \
        --generate-notes \
        --repo "Jinyoung-King/CruxPet"

    RELEASE_CREATED=true

    gh release upload "v${VERSION}" "$DMG_PATH" \
        --repo "Jinyoung-King/CruxPet"

    echo "✅ GitHub 릴리즈 완료: v${VERSION}"
}
```

- [ ] **Step 2: update_appcast 함수 추가**

```bash
# ── appcast.xml 업데이트 ──────────────────────────────────────────────────
update_appcast() {
    echo "📡 appcast.xml 업데이트 중..."

    local DMG_PATH="$REPO_ROOT/$DMG_NAME"

    # 서명 생성
    local SIGNATURE
    SIGNATURE=$("$SPARKLE_BIN/sign_update" "$DMG_PATH")

    # 파일 크기
    local FILE_SIZE
    FILE_SIZE=$(stat -f%z "$DMG_PATH")

    # 현재 build number 읽기
    local BUILD_NUMBER
    BUILD_NUMBER=$(grep -m1 "CURRENT_PROJECT_VERSION" \
        "$REPO_ROOT/CruxPet.xcodeproj/project.pbxproj" | tr -dc '0-9')

    # 다운로드 URL
    local DOWNLOAD_URL="https://github.com/Jinyoung-King/CruxPet/releases/download/v${VERSION}/CruxPet-${VERSION}.dmg"

    # appcast.xml 생성
    python3 - "$VERSION" "$BUILD_NUMBER" "$SIGNATURE" "$FILE_SIZE" "$DOWNLOAD_URL" <<'PYEOF'
import sys
from datetime import datetime, timezone

version, build, signature, size, url = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
pub_date = datetime.now(timezone.utc).strftime('%a, %d %b %Y %H:%M:%S +0000')

xml = f"""<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>CruxPet</title>
    <item>
      <title>Version {version}</title>
      <pubDate>{pub_date}</pubDate>
      <sparkle:version>{build}</sparkle:version>
      <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
      <enclosure
        url="{url}"
        length="{size}"
        type="application/octet-stream"
        sparkle:edSignature="{signature}"
      />
    </item>
  </channel>
</rss>"""

with open('appcast.xml', 'w') as f:
    f.write(xml)
print(f"appcast.xml updated for v{version} (build {build})")
PYEOF

    echo "✅ appcast.xml 업데이트 완료"
}
```

- [ ] **Step 3: finalize 함수 추가**

```bash
# ── 마무리 ────────────────────────────────────────────────────────────────
finalize() {
    echo "🏁 마무리 중..."

    local DMG_PATH="$REPO_ROOT/$DMG_NAME"

    # appcast.xml 커밋
    git -C "$REPO_ROOT" add appcast.xml
    git -C "$REPO_ROOT" commit -m "chore: update appcast for v${VERSION}"

    # 태그 생성
    git -C "$REPO_ROOT" tag "v${VERSION}"

    # DMG 로컬 삭제 (GitHub에 업로드됨)
    rm -f "$DMG_PATH"

    # push
    git -C "$REPO_ROOT" push origin main --tags

    echo ""
    echo "🎉 릴리즈 완료!"
    echo "   버전: v${VERSION}"
    echo "   GitHub: https://github.com/Jinyoung-King/CruxPet/releases/tag/v${VERSION}"
    echo "   기존 앱 사용자에게 업데이트가 전파됩니다."
}
```

- [ ] **Step 4: 스크립트 하단에 함수 호출 추가**

`create_dmg` 아래에 추가:
```bash
create_github_release
update_appcast
finalize
```

- [ ] **Step 5: 전체 스크립트 최종 확인**

완성된 `scripts/release.sh` 전체를 확인. 함수 호출 순서가 맞는지 검증:

```bash
grep -n "^[a-z_]*()$\|^[a-z_]*$" scripts/release.sh | grep -v "^.*#"
```

스크립트 끝부분 (`preflight` 이후 함수 호출)이 이렇게 되어 있어야 함:
```bash
preflight
echo "🚀 릴리즈 $VERSION 시작"
bump_version
build_app
create_dmg
create_github_release
update_appcast
finalize
```

- [ ] **Step 6: update_appcast python3 로직 단위 검증**

실제 릴리즈 없이 python3 스크립트만 따로 테스트:
```bash
python3 - "1.0.6" "7" "TEST_SIGNATURE==" "1234567" \
    "https://github.com/Jinyoung-King/CruxPet/releases/download/v1.0.6/CruxPet-1.0.6.dmg" <<'PYEOF'
import sys
from datetime import datetime, timezone

version, build, signature, size, url = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
pub_date = datetime.now(timezone.utc).strftime('%a, %d %b %Y %H:%M:%S +0000')

xml = f"""<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>CruxPet</title>
    <item>
      <title>Version {version}</title>
      <pubDate>{pub_date}</pubDate>
      <sparkle:version>{build}</sparkle:version>
      <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
      <enclosure
        url="{url}"
        length="{size}"
        type="application/octet-stream"
        sparkle:edSignature="{signature}"
      />
    </item>
  </channel>
</rss>"""

with open('appcast.xml', 'w') as f:
    f.write(xml)
print(f"appcast.xml updated for v{version} (build {build})")
PYEOF
```

Expected: `appcast.xml updated for v1.0.6 (build 7)` 출력 + `appcast.xml` 내용 확인:
```bash
cat appcast.xml
```

`appcast.xml`에 `Version 1.0.6`, `TEST_SIGNATURE==`, `1234567` 등이 있어야 함.

appcast.xml을 테스트 전 내용으로 복원:
```bash
git checkout appcast.xml
```

- [ ] **Step 7: 커밋**

```bash
git add scripts/release.sh
git commit -m "feat: release.sh GitHub 릴리즈, appcast 업데이트, 마무리 추가"
```
