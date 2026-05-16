#!/bin/bash

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Starting QuickTZ backend..."
cd "$PROJECT_DIR/backend"
pkill -f "uvicorn main:app" 2>/dev/null
sleep 1
nohup python3 -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload > /tmp/uvicorn.log 2>&1 &
echo "Backend PID: $!"

echo "Waiting for backend to start..."
sleep 4

echo "Starting ngrok tunnel..."
pkill -f ngrok 2>/dev/null
sleep 1
nohup /tmp/ngrok http 8000 --log=stdout > /tmp/ngrok.log 2>&1 &
sleep 5

NGROK_URL=$(grep -o 'url=https://[^ ]*' /tmp/ngrok.log | tail -1 | sed 's/url=//')

if [ -z "$NGROK_URL" ]; then
  echo "ERROR: Could not get ngrok URL. Check /tmp/ngrok.log"
  exit 1
fi

echo ""
echo "========================================"
echo "  Backend: http://localhost:8000"
echo "  Docs:    http://localhost:8000/docs"
echo "  Public:  $NGROK_URL"
echo "========================================"
echo ""

# Update Flutter app with new ngrok URL
ENDPOINTS_FILE="$PROJECT_DIR/quickt_mobile/lib/core/network/api_endpoints.dart"
sed -i "s|'https://.*ngrok.*\.dev/api/v1'|'$NGROK_URL/api/v1'|g" "$ENDPOINTS_FILE"
sed -i "s|'https://.*ngrok.*\.app/api/v1'|'$NGROK_URL/api/v1'|g" "$ENDPOINTS_FILE"
echo "Flutter app updated with: $NGROK_URL/api/v1"
echo ""
echo "Now run: cd quickt_mobile && flutter run"
