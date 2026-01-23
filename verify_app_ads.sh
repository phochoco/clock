#!/bin/bash

# app-ads.txt 검증 스크립트
# GitHub Pages 배포 후 파일 접근 가능 여부 확인

echo "========================================="
echo "AdMob app-ads.txt 검증 스크립트"
echo "========================================="
echo ""

URL="https://phochoco.github.io/app-ads.txt"
EXPECTED_CONTENT="google.com, pub-7214081640200790, DIRECT, f08c47fec0942fa0"

echo "🔍 검증 URL: $URL"
echo ""

# HTTP 상태 코드 확인
echo "1️⃣  HTTP 상태 코드 확인 중..."
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$STATUS_CODE" -eq 200 ]; then
    echo "✅ HTTP 200 OK - 파일 접근 가능"
else
    echo "❌ HTTP $STATUS_CODE - 파일 접근 불가"
    echo ""
    echo "💡 문제 해결:"
    echo "   - GitHub Pages 배포 대기 중일 수 있습니다 (2-5분)"
    echo "   - 저장소가 Public인지 확인하세요"
    echo "   - 파일이 루트 디렉토리에 있는지 확인하세요"
    exit 1
fi

echo ""

# 파일 내용 확인
echo "2️⃣  파일 내용 확인 중..."
ACTUAL_CONTENT=$(curl -s "$URL" | tr -d '\n\r')

if [ "$ACTUAL_CONTENT" = "$EXPECTED_CONTENT" ]; then
    echo "✅ 파일 내용 정확함"
    echo ""
    echo "📄 내용:"
    echo "   $ACTUAL_CONTENT"
else
    echo "❌ 파일 내용 불일치"
    echo ""
    echo "📄 예상 내용:"
    echo "   $EXPECTED_CONTENT"
    echo ""
    echo "�� 실제 내용:"
    echo "   $ACTUAL_CONTENT"
    echo ""
    echo "💡 문제 해결:"
    echo "   - 파일 내용을 다시 확인하세요"
    echo "   - 줄바꿈이나 공백이 없는지 확인하세요"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ 모든 검증 통과!"
echo "========================================="
echo ""
echo "다음 단계:"
echo "1. AdMob 콘솔 접속: https://apps.admob.com/"
echo "2. '시계배우기' 앱 선택"
echo "3. '업데이트 확인' 버튼 클릭"
echo "4. 24시간 이내 승인 예상"
echo ""
