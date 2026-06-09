# Release Automation — Design Spec

## Goal

`./scripts/release.sh 1.0.6` 한 번으로 버전 번프 → 빌드 → GitHub 릴리즈 생성 → appcast.xml 업데이트 → push까지 전체 배포 파이프라인 자동화.

## Architecture

- **`scripts/release.sh`** (신규): 전체 릴리즈 파이프라인 셸 스크립트
- **`scripts/ExportOptions.plist`** (신규): xcodebuild exportArchive 설정
- **`appcast.xml`** (수정): 스크립트가 자동 업데이트
- **`CruxPet.xcodeproj/project.pbxproj`** (수정): 스크립트가 버전 번프

## Release Flow

```
./scripts/release.sh 1.0.6
        │
        ▼
1. 인자 검증
   - 버전 형식 확인 (X.Y.Z)
   - gh CLI 로그인 상태 확인
   - git working tree 클린 상태 확인
        │
        ▼
2. 버전 번프
   - MARKETING_VERSION → 1.0.6 (sed, pbxproj)
   - CURRENT_PROJECT_VERSION → 현재값 + 1 (sed, pbxproj)
   - git commit "chore: bump version to 1.0.6"
        │
        ▼
3. 빌드
   - xcodebuild archive → /tmp/CruxPet.xcarchive
   - xcodebuild -exportArchive → /tmp/CruxPet-export/CruxPet.app
        │
        ▼
4. DMG 생성
   - hdiutil create → CruxPet-1.0.6.dmg (프로젝트 루트)
        │
        ▼
5. GitHub 릴리즈 생성 + 업로드
   - gh release create v1.0.6 --generate-notes
   - gh release upload v1.0.6 CruxPet-1.0.6.dmg
        │
        ▼
6. appcast.xml 업데이트
   - generate_appcast로 edSignature + 파일 크기 추출
   - python3로 appcast.xml 파싱 및 신규 <item> 삽입 (최신 버전이 첫 번째)
   - 업데이트 내용: version, shortVersionString, pubDate, url, length, edSignature
        │
        ▼
7. 마무리
   - git commit "chore: update appcast for v1.0.6"
   - git tag v1.0.6
   - git push origin main --tags
        │
        ▼
완료! 기존 앱 사용자에게 업데이트 전파
```

## 파일 구조

```
scripts/
  release.sh          # 릴리즈 파이프라인 스크립트
  ExportOptions.plist # xcodebuild export 설정
```

## ExportOptions.plist

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

## appcast.xml 업데이트 방식

`generate_appcast`를 DMG가 있는 디렉터리에 실행하면 `<item>` XML 블록을 stdout으로 출력. 여기서 `edSignature`와 `length`를 추출.

`python3` (macOS 기본 탑재)으로 `appcast.xml`을 최신 버전 단일 항목으로 덮어씀. Sparkle은 최신 항목 하나만 필요하므로 이전 항목은 교체.

다운로드 URL 형식:
```
https://github.com/Jinyoung-King/CruxPet/releases/download/v{VERSION}/CruxPet-{VERSION}.dmg
```

## 사전 조건 (스크립트 시작 시 검사)

| 조건 | 검사 방법 |
|---|---|
| `gh` CLI 설치 + 로그인 | `gh auth status` |
| git working tree 클린 | `git status --porcelain` |
| Xcode 커맨드라인 툴 | `xcodebuild -version` |
| Sparkle generate_appcast | DerivedData 경로 동적 탐색 |

## 오류 처리

- `set -euo pipefail`: 어느 단계든 실패 시 즉시 중단
- `trap`: 종료 시 `/tmp/CruxPet*` 임시 파일 자동 정리
- GitHub release가 이미 생성된 후 실패 시: 수동 삭제 안내 메시지 출력
  ```
  ⚠️  GitHub release v1.0.6이 생성됐습니다. 수동으로 삭제하려면:
      gh release delete v1.0.6 --cleanup-tag
  ```

## DMG 파일 관리

빌드된 `CruxPet-{VERSION}.dmg`는 GitHub Release에 업로드 후 로컬에서 삭제 (`.gitignore`에 `*.dmg` 추가). 현재 루트의 `CruxPet.dmg`도 `.gitignore`로 처리.
