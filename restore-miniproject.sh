#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
DESKTOP="$(dirname "$ROOT")"

echo "▶ 프로젝트 폴더 구조 복구 중..."

# 깨진 빈 miniproject 폴더 제거
if [ -d "$DESKTOP/miniproject" ] && [ ! -f "$DESKTOP/miniproject/backend/main.py" ]; then
  echo "  - 깨진 miniproject 폴더 삭제"
  rm -rf "$DESKTOP/miniproject"
fi

# 소스 / xcodeproj 이름 복구
if [ -d "$ROOT/Footprint" ]; then
  echo "  - Footprint/ → miniproject/"
  mv "$ROOT/Footprint" "$ROOT/miniproject"
fi
if [ -d "$ROOT/Footprint.xcodeproj" ]; then
  echo "  - Footprint.xcodeproj → miniproject.xcodeproj"
  mv "$ROOT/Footprint.xcodeproj" "$ROOT/miniproject.xcodeproj"
fi

# Desktop/Footprint → Desktop/miniproject
if [ "$(basename "$ROOT")" = "Footprint" ]; then
  echo "  - Desktop/Footprint → Desktop/miniproject"
  mv "$ROOT" "$DESKTOP/miniproject"
  ROOT="$DESKTOP/miniproject"
fi

echo ""
echo "✅ 완료! Xcode에서 아래 파일을 여세요:"
echo "   $ROOT/miniproject.xcodeproj"
echo ""
open "$ROOT/miniproject.xcodeproj" 2>/dev/null || true
