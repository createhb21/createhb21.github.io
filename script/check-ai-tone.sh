#!/usr/bin/env bash
set -euo pipefail

# 간단한 정적 점검기: AI 티가 나기 쉬운 문장 패턴을 카운트합니다.
# 사용법:
#   script/check-ai-tone.sh _posts/2026-02-15-vibe-coding-club-basic-week1.md
#   script/check-ai-tone.sh _posts/*.md

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <markdown files...>" >&2
  exit 1
fi

patterns=(
  "핵심은"
  "정리하면"
  "결론적으로"
  "패러다임"
  "본질"
  "가능성"
  "핵심 요약"
)

echo "== AI-tone quick check =="
for file in "$@"; do
  [ -f "$file" ] || { echo "[skip] $file (not found)"; continue; }

  echo
  echo "# $file"

  total=0
  for p in "${patterns[@]}"; do
    c=$( (rg -n "$p" "$file" || true) | wc -l | tr -d ' ' )
    total=$((total + c))
    printf -- "- %-12s : %s\n" "$p" "$c"
  done

  step_count=$( (rg -n "Step [0-9]+" "$file" || true) | wc -l | tr -d ' ' )
  echo "- Step n 패턴   : $step_count"

  if [ "$total" -ge 8 ]; then
    echo "⚠️  경고: 템플릿성 문구가 많은 편입니다. 경험 문장 추가를 권장합니다."
  else
    echo "✅ 양호: 반복 패턴 수치가 과도하지 않습니다."
  fi
done
